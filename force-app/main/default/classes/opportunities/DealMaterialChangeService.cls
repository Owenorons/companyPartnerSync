/**
 * Evaluates whether Opportunity-side drift detected by
 * DealOpportunityReconciliationBatch (customer, amount, close date, or
 * owner changed since Deal_Registration__c's approval snapshot - see
 * DealCommandService.captureApprovalSnapshot) is material enough to
 * require reapproval, per Deal_Material_Change_Policy__mdt (Sprint 39
 * §39.31-39.33).
 *
 * A material change that requires reapproval regenerates the approval plan
 * (ApprovalPlanService, confirmed reusable/object-agnostic) and moves the
 * deal back to Under Review via the standard DealCommandService/
 * Deal_State_Transition__mdt path, not a direct field write - reapproval
 * is a governed lifecycle transition like any other. A change that isn't
 * material enough is just logged (AcknowledgeMaterialChange - visible in
 * the audit trail, no state change).
 */
public without sharing class DealMaterialChangeService {
  /**
   * Evaluates one detected change and, if the resolved policy requires it,
   * requests reapproval; otherwise logs the change without altering the
   * deal's state.
   *
   * @param dealId Id of the affected deal.
   * @param changeType One of CustomerChanged/AmountChanged/CloseDateChanged/OwnerChanged.
   * @param description Human-readable description of what changed, for the audit log/reapproval reason.
   * @param observedValue The new (Opportunity-side) value, for AmountChanged's variance check.
   * @param approvedValue The previously-approved value, for AmountChanged's variance check.
   */
  public static void evaluate(
    Id dealId,
    String changeType,
    String description,
    Decimal observedValue,
    Decimal approvedValue
  ) {
    Deal_Material_Change_Policy__mdt policy = resolvePolicy(changeType);
    if (policy == null || policy.Active__c != true) {
      acknowledgeMaterialChange(dealId, changeType, description);
      return;
    }

    Boolean material = isMaterial(policy, observedValue, approvedValue);
    if (!material || policy.Require_Reapproval__c != true) {
      acknowledgeMaterialChange(dealId, changeType, description);
      return;
    }

    requestReapproval(dealId, changeType, description);
  }

  private static Boolean isMaterial(
    Deal_Material_Change_Policy__mdt policy,
    Decimal observedValue,
    Decimal approvedValue
  ) {
    if (policy.Variance_Threshold_Percent__c == null) {
      return true;
    }
    if (approvedValue == null || approvedValue == 0 || observedValue == null) {
      return true;
    }
    Decimal variancePercent =
      ((observedValue - approvedValue).abs() * 100) / approvedValue.abs();
    return variancePercent > policy.Variance_Threshold_Percent__c;
  }

  private static void requestReapproval(
    Id dealId,
    String changeType,
    String description
  ) {
    List<Deal_Registration__c> deals = [
      SELECT Id, Name, Customer_Name__c, Estimated_Revenue__c, Version_Number__c
      FROM Deal_Registration__c
      WHERE Id = :dealId
      WITH SYSTEM_MODE
    ];
    if (deals.isEmpty()) {
      return;
    }
    Deal_Registration__c deal = deals[0];
    Integer version = deal.Version_Number__c == null
      ? 0
      : Integer.valueOf(deal.Version_Number__c);

    String targetLabel =
      deal.Name +
      (String.isBlank(deal.Customer_Name__c)
        ? ''
        : ' — ' + deal.Customer_Name__c);
    ApprovalPlanService.generate(
      'Deal_Registration__c',
      new Set<Id>{ dealId },
      new Map<Id, Decimal>{ dealId => deal.Estimated_Revenue__c },
      new Map<Id, String>{ dealId => targetLabel },
      new Map<Id, Integer>{ dealId => version + 1 }
    );

    DealCommand command = new DealCommand();
    command.dealId = dealId;
    command.aggregateId = dealId;
    command.aggregateType = DealLifecycleConstants.AGGREGATE_REGISTRATION;
    command.lifecycleDimension = DealLifecycleConstants.DIMENSION_REGISTRATION;
    command.commandType = DealRegistrationLifecycleConstants.REQUEST_REAPPROVAL;
    command.commandKey =
      'material-change-' +
      changeType +
      '-' +
      dealId +
      '-' +
      version;
    command.expectedVersion = version;
    command.reason = String.isBlank(description)
      ? 'A material change (' + changeType + ') requires reapproval.'
      : description;
    DealCommandService.execute(command);
  }

  private static void acknowledgeMaterialChange(
    Id dealId,
    String changeType,
    String description
  ) {
    AuditLogRequestDTO request = AuditFactory.createSuccess(
      'Deal_Registration__c',
      dealId,
      'Acknowledge Material Change'
    );
    request.metadataJson = JSON.serialize(
      new Map<String, Object>{
        'changeType' => changeType,
        'description' => String.isBlank(description)
          ? 'A non-material change was detected and requires no reapproval.'
          : description
      }
    );
    AuditService.log(request);
  }

  private static Deal_Material_Change_Policy__mdt resolvePolicy(
    String changeType
  ) {
    List<Deal_Material_Change_Policy__mdt> rows = [
      SELECT
        Change_Type__c,
        Require_Reapproval__c,
        Variance_Threshold_Percent__c,
        Active__c
      FROM Deal_Material_Change_Policy__mdt
      WHERE Active__c = TRUE AND Change_Type__c = :changeType
      WITH SYSTEM_MODE
      LIMIT 1
    ];
    return rows.isEmpty() ? null : rows[0];
  }
}
