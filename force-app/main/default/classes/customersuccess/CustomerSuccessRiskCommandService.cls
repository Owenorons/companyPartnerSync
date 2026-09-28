/**
 * Executes Customer_Success_Risk__c commands: raise, resolve, accept.
 * raise/resolve trigger CustomerSuccessHealthService.recompute() so the
 * engagement's health reflects the current open-risk roster immediately -
 * the same shape as ImplementationIssueCommandService for implementations.
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class CustomerSuccessRiskCommandService {
  /**
   * Raises a new risk on an engagement.
   *
   * @param command engagementId + riskType + severity + description (required).
   * @return The inserted risk.
   */
  public static Customer_Success_Risk__c raise(
    CustomerSuccessRiskCommand command
  ) {
    assertManageRiskAuthority();
    if (
      command.engagementId == null ||
      String.isBlank(command.riskType) ||
      String.isBlank(command.description)
    ) {
      throw new PartnerSyncHandledException(
        'An engagement, risk type, and description are required.'
      );
    }

    Customer_Success_Risk__c risk = new Customer_Success_Risk__c(
      Customer_Success_Engagement__c = command.engagementId,
      Risk_Type__c = command.riskType,
      Severity__c = String.isBlank(command.severity)
        ? 'Medium'
        : command.severity,
      Status__c = 'Open',
      Description__c = command.description,
      Raised_On__c = System.now(),
      Raised_By__c = UserInfo.getUserId()
    );
    Database.insert(risk, AccessLevel.SYSTEM_MODE);

    PlatformEventPublisherService.publish(
      'CustomerRiskRaised',
      command.engagementId,
      'Customer_Success_Engagement__c',
      null,
      'A customer success risk was raised.',
      risk.Severity__c == 'Critical' ? 'Error' : 'Warning'
    );

    CustomerSuccessHealthService.recompute(command.engagementId);

    return risk;
  }

  /**
   * Resolves an open risk, requiring a resolution description.
   *
   * @param command riskId + resolution.
   * @return The updated risk.
   */
  public static Customer_Success_Risk__c resolve(
    CustomerSuccessRiskCommand command
  ) {
    assertManageRiskAuthority();
    if (String.isBlank(command.resolution)) {
      throw new PartnerSyncHandledException(
        'A resolution description is required to resolve a risk.'
      );
    }
    Customer_Success_Risk__c risk = requireOpenRisk(command);

    risk.Status__c = 'Resolved';
    risk.Resolution__c = command.resolution;
    risk.Resolved_On__c = System.now();
    Database.update(risk, AccessLevel.SYSTEM_MODE);

    PlatformEventPublisherService.publish(
      'CustomerRiskResolved',
      risk.Customer_Success_Engagement__c,
      'Customer_Success_Engagement__c',
      null,
      'A customer success risk was resolved.',
      'Info'
    );

    CustomerSuccessHealthService.recompute(risk.Customer_Success_Engagement__c);

    return risk;
  }

  /**
   * Accepts the risk rather than resolving it.
   *
   * @param command riskId + reason.
   * @return The updated risk.
   */
  public static Customer_Success_Risk__c accept(
    CustomerSuccessRiskCommand command
  ) {
    assertManageRiskAuthority();
    if (String.isBlank(command.reason)) {
      throw new PartnerSyncHandledException(
        'A reason is required to accept a risk.'
      );
    }
    Customer_Success_Risk__c risk = requireOpenRisk(command);

    risk.Status__c = 'Accepted';
    risk.Resolution__c = command.reason;
    risk.Resolved_On__c = System.now();
    Database.update(risk, AccessLevel.SYSTEM_MODE);

    CustomerSuccessHealthService.recompute(risk.Customer_Success_Engagement__c);

    return risk;
  }

  private static void assertManageRiskAuthority() {
    if (
      !PartnerAccessService.isInternalUser() ||
      !DealLifecyclePermissionService.hasPermission(
        'PartnerSync_Manage_Customer_Risk'
      )
    ) {
      throw new PartnerSyncHandledException(
        'Current user lacks authority to manage customer success risks.'
      );
    }
  }

  private static Customer_Success_Risk__c requireOpenRisk(
    CustomerSuccessRiskCommand command
  ) {
    if (command.riskId == null) {
      throw new PartnerSyncHandledException(
        'A risk is required for this command.'
      );
    }
    Customer_Success_Risk__c risk = CustomerSuccessRiskSelector.selectForUpdate(
      command.riskId
    );
    if (
      risk.Status__c == 'Resolved' ||
      risk.Status__c == 'Accepted' ||
      risk.Status__c == 'Closed'
    ) {
      throw new PartnerSyncHandledException(
        'This risk has already been closed out.'
      );
    }
    return risk;
  }
}
