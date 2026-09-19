/**
 * Best-effort audit trail for lead distribution actions (assign/accept/
 * reject), writing to Lead_Distribution_Log__c.
 */
public with sharing class LeadDistributionLogService {
  /**
   * Records a lead distribution action to the audit log. Never throws:
   * a missing create permission or insert failure is logged and swallowed
   * so logging can never block the caller's primary lead operation.
   *
   * @param leadId Id of the Lead the action relates to.
   * @param partnerAccountId Id of the partner Account involved in the action.
   * @param partnerContactId Id of the partner Contact involved in the action.
   * @param action The action performed (e.g. Assigned, Accepted, Rejected).
   * @param status The lead's resulting distribution status.
   * @param notes Optional notes to attach to the log entry.
   */
  public static void logAction(
    Id leadId,
    Id partnerAccountId,
    Id partnerContactId,
    String action,
    String status,
    String notes
  ) {
    // Logging must never block the actual lead assignment/decision it's
    // recording, so a missing FLS grant is treated as a soft skip (warn +
    // return) rather than an exception.
    if (!Schema.sObjectType.Lead_Distribution_Log__c.isCreateable()) {
      LoggingService.warn(
        'LeadDistributionLogService',
        'Skipping lead distribution log because user lacks create access.'
      );
      return;
    }

    // Same reasoning as above: any other insert failure here is caught and
    // logged rather than propagated, so a logging problem can't fail the
    // caller's primary operation.
    try {
      Lead_Distribution_Log__c log = new Lead_Distribution_Log__c();
      log.Lead__c = leadId;
      log.Partner_Account__c = partnerAccountId;
      log.Partner_Contact__c = partnerContactId;
      log.Action__c = action;
      log.Status__c = status;
      log.Notes__c = notes;
      log.Performed_By__c = UserInfo.getUserId();
      log.Performed_On__c = System.now();

      insert SecurityUtil.stripForCreate(new List<SObject>{ log });
    } catch (Exception ex) {
      LoggingService.error(
        'LeadDistributionLogService',
        'Unable to create lead distribution log.',
        ex
      );
    }
  }
}
