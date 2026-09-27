/**
 * Executes Implementation_Acceptance__c commands: request, record,
 * reject. record() delegates the actual acceptance-recording to an
 * ImplementationAcceptanceAdapter (only SalesforceHostedAcceptanceAdapter
 * exists today) so a future e-sign mode is a clean addition.
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class ImplementationAcceptanceCommandService {
  @TestVisible
  private static ImplementationAcceptanceAdapter testAdapter;

  /**
   * Requests a new customer acceptance on an implementation.
   *
   * @param command implementationId + acceptanceType + customerContactId.
   * @return The inserted acceptance record.
   */
  public static Implementation_Acceptance__c request(
    ImplementationAcceptanceCommand command
  ) {
    PartnerAccessService.assertInternalUser();
    if (
      command.implementationId == null || String.isBlank(command.acceptanceType)
    ) {
      throw new PartnerSyncHandledException(
        'An implementation and an acceptance type are required.'
      );
    }

    Implementation_Acceptance__c acceptance = new Implementation_Acceptance__c(
      Implementation__c = command.implementationId,
      Acceptance_Type__c = command.acceptanceType,
      Status__c = 'Requested',
      Requested_On__c = System.now(),
      Requested_By__c = UserInfo.getUserId(),
      Customer_Contact__c = command.customerContactId,
      Version_Number__c = 0
    );
    Database.insert(acceptance, AccessLevel.SYSTEM_MODE);

    updateImplementationStatus(
      command.implementationId,
      'Pending Customer Acceptance'
    );

    PlatformEventPublisherService.publish(
      'CustomerAcceptanceRequested',
      command.implementationId,
      'Deal_Implementation__c',
      null,
      'Customer acceptance was requested.',
      'Info'
    );

    return acceptance;
  }

  /**
   * Records acceptance via the resolved ImplementationAcceptanceAdapter.
   *
   * @param command acceptanceId + expectedVersion + acceptedByName/Email.
   */
  public static void record(ImplementationAcceptanceCommand command) {
    Implementation_Acceptance__c acceptance = selectAndCheckVersion(command);
    if (
      acceptance.Status__c != 'Requested' &&
      acceptance.Status__c != 'Pending'
    ) {
      throw new PartnerSyncHandledException(
        'This acceptance is not in a state that can be accepted.'
      );
    }

    resolveAdapter()
      .applyAcceptance(
        acceptance,
        command.acceptedByName,
        command.acceptedByEmail
      );
    acceptance.Version_Number__c = versionAfter(acceptance);
    Database.update(acceptance, AccessLevel.SYSTEM_MODE);

    PlatformEventPublisherService.publish(
      'CustomerAcceptanceReceived',
      acceptance.Implementation__c,
      'Deal_Implementation__c',
      null,
      'Customer acceptance was received.',
      'Info'
    );

    if (
      !ImplementationAcceptanceSelector.hasUnacceptedRequiredAcceptance(
        acceptance.Implementation__c
      )
    ) {
      updateImplementationStatus(
        acceptance.Implementation__c,
        'Customer Accepted'
      );
    }
  }

  /**
   * Records a customer rejection, requiring a reason. Returns the
   * implementation to In Progress rather than erasing the acceptance
   * request's history.
   *
   * @param command acceptanceId + expectedVersion + reason.
   */
  public static void reject(ImplementationAcceptanceCommand command) {
    PartnerAccessService.assertInternalUser();
    if (String.isBlank(command.reason)) {
      throw new PartnerSyncHandledException(
        'A reason is required to record a customer rejection.'
      );
    }
    Implementation_Acceptance__c acceptance = selectAndCheckVersion(command);
    if (
      acceptance.Status__c != 'Requested' &&
      acceptance.Status__c != 'Pending'
    ) {
      throw new PartnerSyncHandledException(
        'This acceptance is not in a state that can be rejected.'
      );
    }

    acceptance.Status__c = 'Rejected';
    acceptance.Rejection_Reason__c = command.reason;
    acceptance.Version_Number__c = versionAfter(acceptance);
    Database.update(acceptance, AccessLevel.SYSTEM_MODE);

    updateImplementationStatus(acceptance.Implementation__c, 'In Progress');

    PlatformEventPublisherService.publish(
      'CustomerAcceptanceRejected',
      acceptance.Implementation__c,
      'Deal_Implementation__c',
      null,
      'Customer acceptance was rejected.',
      'Warning'
    );
  }

  // Every method here mutates Deal_Implementation__c.Status__c as a
  // side effect - this keeps Version_Number__c in step so
  // ImplementationCommandService's own optimistic-concurrency contract
  // isn't silently bypassed by a stale-but-unversioned write.
  private static void updateImplementationStatus(
    Id implementationId,
    String status
  ) {
    Deal_Implementation__c implementation = ImplementationSelector.selectForUpdate(
      implementationId
    );
    implementation.Status__c = status;
    implementation.Version_Number__c =
      (implementation.Version_Number__c == null
        ? 0
        : Integer.valueOf(implementation.Version_Number__c)) + 1;
    Database.update(implementation, AccessLevel.SYSTEM_MODE);
  }

  private static ImplementationAcceptanceAdapter resolveAdapter() {
    if (Test.isRunningTest() && testAdapter != null) {
      return testAdapter;
    }
    return new SalesforceHostedAcceptanceAdapter();
  }

  private static Implementation_Acceptance__c selectAndCheckVersion(
    ImplementationAcceptanceCommand command
  ) {
    if (command.acceptanceId == null) {
      throw new PartnerSyncHandledException(
        'An acceptance record is required for this command.'
      );
    }
    Implementation_Acceptance__c acceptance = ImplementationAcceptanceSelector.selectForUpdate(
      command.acceptanceId
    );
    Integer version = acceptance.Version_Number__c == null
      ? 0
      : Integer.valueOf(acceptance.Version_Number__c);
    if (command.expectedVersion == null || command.expectedVersion != version) {
      throw new PartnerSyncHandledException(
        'This acceptance record changed. Refresh before retrying.'
      );
    }
    return acceptance;
  }

  private static Integer versionAfter(Implementation_Acceptance__c acceptance) {
    Integer current = acceptance.Version_Number__c == null
      ? 0
      : Integer.valueOf(acceptance.Version_Number__c);
    return current + 1;
  }
}
