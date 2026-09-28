/**
 * Executes Customer_Success_Engagement__c commands: createEngagement (the
 * sole consumer of CustomerSuccessHandoffRequested, invoked by
 * CustomerSuccessEventConsumerService), acceptHandoff, recordChurn, and
 * reopenEngagement. Doc Sprint 42's core principle: a successful
 * implementation does not end the partner relationship - it establishes
 * the governed customer relationship this object represents.
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class CustomerSuccessCommandService {
  /**
   * Creates a Pending Handoff engagement for a deal whose implementation
   * just completed, resolving the completed Deal_Implementation__c row for
   * a Handoff_Snapshot__c JSON snapshot (doc section 42.7). Idempotent: a
   * redelivered CustomerSuccessHandoffRequested event for a deal that
   * already has an engagement is a no-op, since platform events can be
   * redelivered.
   *
   * @param dealId Id of the Deal_Registration__c the completed implementation belongs to.
   * @return The existing or newly-created engagement.
   */
  public static Customer_Success_Engagement__c createEngagement(Id dealId) {
    if (dealId == null) {
      throw new PartnerSyncHandledException(
        'A deal is required to create a Customer Success engagement.'
      );
    }

    Customer_Success_Engagement__c existing = CustomerSuccessSelector.selectByOriginatingDeal(
      dealId
    );
    if (existing != null) {
      return existing;
    }

    Deal_Implementation__c implementation = resolveCompletedImplementation(
      dealId
    );

    Customer_Success_Engagement__c engagement = new Customer_Success_Engagement__c(
      Customer_Account__c = implementation?.Customer_Account__c,
      Originating_Deal__c = dealId,
      Originating_Opportunity__c = implementation?.Opportunity__c,
      Implementation__c = implementation?.Id,
      Primary_Partner__c = implementation?.Primary_Partner__c,
      Primary_Participant__c = implementation?.Primary_Participant__c,
      Status__c = 'Pending Handoff',
      Health_Status__c = 'Not Assessed',
      Handoff_Snapshot__c = buildHandoffSnapshot(implementation),
      Version_Number__c = 0
    );
    Database.insert(engagement, AccessLevel.SYSTEM_MODE);

    PlatformEventPublisherService.publish(
      'CustomerSuccessEngagementCreated',
      engagement.Id,
      'Customer_Success_Engagement__c',
      engagement.Primary_Partner__c,
      'A customer success engagement was created from a completed implementation.',
      'Info'
    );

    return engagement;
  }

  /**
   * Accepts a Pending Handoff engagement into active Customer Success
   * ownership, optionally assigning the internal/partner success owners.
   *
   * @param command engagementId + expectedVersion + optional owner assignments.
   * @return The updated engagement.
   */
  public static Customer_Success_Engagement__c acceptHandoff(
    CustomerSuccessCommand command
  ) {
    assertManageAuthority();
    Customer_Success_Engagement__c engagement = requireExpectedVersion(command);

    if (engagement.Status__c != 'Pending Handoff') {
      throw new PartnerSyncHandledException(
        'Only a Pending Handoff engagement can be accepted.'
      );
    }

    engagement.Status__c = 'Active';
    if (command.internalOwnerId != null) {
      engagement.Internal_Customer_Success_Owner__c = command.internalOwnerId;
    }
    if (command.partnerSuccessOwnerId != null) {
      engagement.Partner_Success_Owner__c = command.partnerSuccessOwnerId;
    }
    engagement.Version_Number__c = coalesceVersion(engagement) + 1;
    Database.update(engagement, AccessLevel.SYSTEM_MODE);

    CustomerSuccessSharingService.reconcileForEngagement(engagement.Id);

    PlatformEventPublisherService.publish(
      'CustomerSuccessHandoffAccepted',
      engagement.Id,
      'Customer_Success_Engagement__c',
      engagement.Primary_Partner__c,
      'A customer success handoff was accepted.',
      'Info'
    );

    return engagement;
  }

  /**
   * Records a customer as churned - a distinct, explicit action, never an
   * automatic side effect of a renewal being lost (doc section 42.31,
   * enforced by RenewalCommandService.markNotRenewed() deliberately not
   * calling this).
   *
   * @param command engagementId + expectedVersion + reason + churnCategory (required).
   * @return The updated engagement.
   */
  public static Customer_Success_Engagement__c recordChurn(
    CustomerSuccessCommand command
  ) {
    assertManageAuthority();
    if (
      String.isBlank(command.reason) || String.isBlank(command.churnCategory)
    ) {
      throw new PartnerSyncHandledException(
        'A reason and churn category are required to record churn.'
      );
    }
    Customer_Success_Engagement__c engagement = requireExpectedVersion(command);
    if (engagement.Status__c == 'Churned') {
      throw new PartnerSyncHandledException(
        'This engagement has already been recorded as churned.'
      );
    }

    engagement.Status__c = 'Churned';
    engagement.Health_Status__c = 'Churned';
    engagement.Churned_On__c = System.today();
    engagement.Churn_Reason__c = command.reason;
    engagement.Churn_Category__c = command.churnCategory;
    engagement.Churn_Notes__c = command.churnNotes;
    engagement.Version_Number__c = coalesceVersion(engagement) + 1;
    Database.update(engagement, AccessLevel.SYSTEM_MODE);

    PlatformEventPublisherService.publish(
      'CustomerChurned',
      engagement.Id,
      'Customer_Success_Engagement__c',
      engagement.Primary_Partner__c,
      'A customer was recorded as churned.',
      'Warning'
    );

    return engagement;
  }

  /**
   * Re-engages a churned customer under a brand-new engagement row rather
   * than resurrecting the churned one in place, carrying forward the
   * customer/partner context and linking Previous_Engagement__c back to
   * the churned row for history.
   *
   * @param command engagementId (the churned engagement) + reason.
   * @return The newly-created engagement.
   */
  public static Customer_Success_Engagement__c reopenEngagement(
    CustomerSuccessCommand command
  ) {
    assertManageAuthority();
    if (command.engagementId == null) {
      throw new PartnerSyncHandledException(
        'An engagement is required to reopen.'
      );
    }
    if (String.isBlank(command.reason)) {
      throw new PartnerSyncHandledException(
        'A reason is required to reopen an engagement.'
      );
    }
    Customer_Success_Engagement__c previous = CustomerSuccessSelector.selectForUpdate(
      command.engagementId
    );
    if (previous.Status__c != 'Churned') {
      throw new PartnerSyncHandledException(
        'Only a churned engagement can be reopened.'
      );
    }
    if (CustomerSuccessSelector.hasSubsequentEngagement(previous.Id)) {
      throw new PartnerSyncHandledException(
        'This engagement has already been reopened.'
      );
    }

    Customer_Success_Engagement__c reopened = new Customer_Success_Engagement__c(
      Customer_Account__c = previous.Customer_Account__c,
      Originating_Deal__c = previous.Originating_Deal__c,
      Originating_Opportunity__c = previous.Originating_Opportunity__c,
      Implementation__c = previous.Implementation__c,
      Primary_Partner__c = previous.Primary_Partner__c,
      Primary_Participant__c = previous.Primary_Participant__c,
      Previous_Engagement__c = previous.Id,
      Status__c = 'Active',
      Health_Status__c = 'Not Assessed',
      Version_Number__c = 0
    );
    Database.insert(reopened, AccessLevel.SYSTEM_MODE);

    PlatformEventPublisherService.publish(
      'CustomerSuccessEngagementCreated',
      reopened.Id,
      'Customer_Success_Engagement__c',
      reopened.Primary_Partner__c,
      'A previously churned customer re-engaged: ' + command.reason,
      'Info'
    );

    return reopened;
  }

  private static void assertManageAuthority() {
    if (
      !PartnerAccessService.isInternalUser() ||
      !DealLifecyclePermissionService.hasPermission(
        'PartnerSync_Manage_Customer_Success'
      )
    ) {
      throw new PartnerSyncHandledException(
        'Current user lacks authority to manage this customer success engagement.'
      );
    }
  }

  private static Customer_Success_Engagement__c requireExpectedVersion(
    CustomerSuccessCommand command
  ) {
    if (command.engagementId == null) {
      throw new PartnerSyncHandledException(
        'An engagement is required for this command.'
      );
    }
    Customer_Success_Engagement__c engagement = CustomerSuccessSelector.selectForUpdate(
      command.engagementId
    );
    if (
      command.expectedVersion != null &&
      coalesceVersion(engagement) != command.expectedVersion
    ) {
      throw new PartnerSyncHandledException(
        'This engagement has changed since it was loaded - refresh and try again.'
      );
    }
    return engagement;
  }

  private static Integer coalesceVersion(
    Customer_Success_Engagement__c engagement
  ) {
    return engagement.Version_Number__c == null
      ? 0
      : Integer.valueOf(engagement.Version_Number__c);
  }

  private static Deal_Implementation__c resolveCompletedImplementation(
    Id dealId
  ) {
    List<Deal_Implementation__c> rows = [
      SELECT
        Id,
        Opportunity__c,
        Customer_Account__c,
        Primary_Partner__c,
        Primary_Participant__c,
        Status__c,
        Health__c,
        Implementation_Type__c,
        Actual_Start_Date__c,
        Actual_Completion_Date__c
      FROM Deal_Implementation__c
      WHERE Deal__c = :dealId AND Status__c = 'Completed'
      WITH SYSTEM_MODE
      ORDER BY Actual_Completion_Date__c DESC
      LIMIT 1
    ];
    return rows.isEmpty() ? null : rows[0];
  }

  private static String buildHandoffSnapshot(
    Deal_Implementation__c implementation
  ) {
    if (implementation == null) {
      return null;
    }
    Map<String, Object> snapshot = new Map<String, Object>{
      'implementationId' => implementation.Id,
      'implementationType' => implementation.Implementation_Type__c,
      'finalHealth' => implementation.Health__c,
      'actualStartDate' => implementation.Actual_Start_Date__c,
      'actualCompletionDate' => implementation.Actual_Completion_Date__c,
      'capturedOn' => System.now()
    };
    return JSON.serialize(snapshot);
  }
}
