/** Persists individual activation gates and controls post-onboarding lifecycle state. */
public without sharing class PartnerReadinessLifecycleService {
  @TestVisible
  private static Boolean testAccountPartnerEnabled = false;
  @TestVisible
  private static Boolean testLifecycleAuthority = false;

  /**
   * Result of evaluating an onboarding's activation gates, showing which
   * individual gates passed and any blockers preventing readiness.
   */
  public class GateResult {
    /**
     * Whether all activation gates passed.
     */
    @AuraEnabled
    public Boolean ready;
    /**
     * Pass/fail state of each individual activation gate, keyed by gate
     * name.
     */
    @AuraEnabled
    public Map<String, Boolean> gates = new Map<String, Boolean>();
    /**
     * Human-readable descriptions of any failed gates.
     */
    @AuraEnabled
    public List<String> blockers = new List<String>();
  }

  /**
   * Assigns (or re-assigns) a training item to a partner onboarding.
   * Requires partner lifecycle management authority.
   *
   * @param onboardingId Id of the Partner_Onboarding__c the training is
   * assigned to.
   * @param trainingKey Key identifying the training item.
   * @param mandatory Whether completing the training is mandatory for
   * readiness.
   * @param dueOn Date the training assignment is due.
   * @return The created or updated Partner_Training_Assignment__c record.
   */
  public static Partner_Training_Assignment__c assignTraining(
    Id onboardingId,
    String trainingKey,
    Boolean mandatory,
    Date dueOn
  ) {
    assertLifecycleAuthority();
    Partner_Training_Assignment__c assignment = new Partner_Training_Assignment__c(
      Onboarding__c = onboardingId,
      Assignment_Key__c = onboardingId + ':' + trainingKey,
      Training_Key__c = trainingKey,
      Mandatory__c = mandatory,
      Status__c = 'Assigned',
      Due_On__c = dueOn
    );
    Database.upsert(
      assignment,
      Partner_Training_Assignment__c.Fields.Assignment_Key__c,
      AccessLevel.SYSTEM_MODE
    );
    return assignment;
  }

  /**
   * The set of gate keys a Partner_Exception__c may waive, matching the
   * keys evaluate() populates in GateResult.gates.
   */
  private static final Set<String> VALID_GATES = new Set<String>{
    'documents',
    'risk',
    'approval',
    'agreements',
    'relationship',
    'access',
    'training'
  };

  /**
   * Lists the exceptions granted against an onboarding, most recent
   * first. Requires partner lifecycle management authority.
   *
   * @param onboardingId Id of the Partner_Onboarding__c to list exceptions for.
   * @return The onboarding's Partner_Exception__c records.
   */
  public static List<Partner_Exception__c> getExceptions(Id onboardingId) {
    assertLifecycleAuthority();
    return [
      SELECT
        Id,
        Gate__c,
        Reason__c,
        Status__c,
        Effective_On__c,
        Expires_On__c,
        Approved_By__r.Name,
        CreatedDate
      FROM Partner_Exception__c
      WHERE Onboarding__c = :onboardingId
      WITH SYSTEM_MODE
      ORDER BY CreatedDate DESC
    ];
  }

  /**
   * Grants a time-bounded exception waiving one activation gate for an
   * onboarding. While active and current (on or after Effective_On__c,
   * and before Expires_On__c if set), evaluate() treats the named gate as
   * passed regardless of its underlying condition. Requires partner
   * lifecycle management authority.
   *
   * @param onboardingId Id of the Partner_Onboarding__c the exception applies to.
   * @param gate The gate key to waive (see VALID_GATES).
   * @param reason Reason the exception was granted.
   * @param effectiveOn Date the exception starts applying.
   * @param expiresOn Date the exception stops applying, if any.
   * @return The created Partner_Exception__c record.
   */
  public static Partner_Exception__c grantException(
    Id onboardingId,
    String gate,
    String reason,
    Date effectiveOn,
    Date expiresOn
  ) {
    assertLifecycleAuthority();
    if (!VALID_GATES.contains(gate)) {
      throw new IllegalArgumentException('Unsupported gate: ' + gate);
    }
    if (String.isBlank(reason) || effectiveOn == null) {
      throw new IllegalArgumentException(
        'A reason and effective date are required.'
      );
    }
    if (expiresOn != null && expiresOn < effectiveOn) {
      throw new IllegalArgumentException(
        'Expiry date cannot be before the effective date.'
      );
    }
    Partner_Exception__c exception = new Partner_Exception__c(
      Onboarding__c = onboardingId,
      Exception_Key__c = onboardingId +
        ':' +
        gate +
        ':' +
        Datetime.now().getTime(),
      Gate__c = gate,
      Reason__c = reason,
      Approved_By__c = UserInfo.getUserId(),
      Status__c = 'Active',
      Effective_On__c = effectiveOn,
      Expires_On__c = expiresOn
    );
    Database.insert(exception, AccessLevel.SYSTEM_MODE);
    return exception;
  }

  /**
   * Revokes a previously granted exception; the gate it was waiving
   * reverts to its normal, underlying condition on the next evaluate().
   * Requires partner lifecycle management authority.
   *
   * @param exceptionId Id of the Partner_Exception__c to revoke.
   * @param reason Reason the exception is being revoked.
   * @return The updated, now-Revoked Partner_Exception__c record.
   */
  public static Partner_Exception__c revokeException(
    Id exceptionId,
    String reason
  ) {
    assertLifecycleAuthority();
    if (String.isBlank(reason)) {
      throw new IllegalArgumentException('A revocation reason is required.');
    }
    Partner_Exception__c exception = [
      SELECT Id, Status__c, Reason__c
      FROM Partner_Exception__c
      WHERE Id = :exceptionId
      WITH SYSTEM_MODE
      LIMIT 1
      FOR UPDATE
    ];
    exception.Status__c = 'Revoked';
    exception.Reason__c = exception.Reason__c + '\nRevoked: ' + reason;
    Database.update(exception, AccessLevel.SYSTEM_MODE);
    return exception;
  }

  /**
   * Evaluates all activation gates (documents, risk, approval, agreements,
   * relationship, access, training) for an onboarding, persists a
   * readiness assessment and updates the onboarding's gate status.
   * Requires partner lifecycle management authority.
   *
   * @param onboardingId Id of the Partner_Onboarding__c to evaluate.
   * @return A GateResult describing readiness and any blockers found.
   */
  public static GateResult evaluate(Id onboardingId) {
    assertLifecycleAuthority();
    Partner_Onboarding__c onboarding = [
      SELECT Id, Status__c
      FROM Partner_Onboarding__c
      WHERE Id = :onboardingId
      WITH SYSTEM_MODE
      LIMIT 1
      FOR UPDATE
    ];
    GateResult result = new GateResult();
    Set<String> waivedGates = new Set<String>();
    for (Partner_Exception__c activeException : [
      SELECT Gate__c
      FROM Partner_Exception__c
      WHERE
        Onboarding__c = :onboardingId
        AND Status__c = 'Active'
        AND Effective_On__c <= TODAY
        AND (Expires_On__c = NULL
        OR Expires_On__c >= TODAY)
      WITH SYSTEM_MODE
    ]) {
      waivedGates.add(activeException.Gate__c);
    }
    Integer documentTotal = [
      SELECT COUNT()
      FROM Partner_Document_Requirement__c
      WHERE Onboarding__c = :onboardingId AND Blocking__c = TRUE
      WITH SYSTEM_MODE
    ];
    Integer documentOpen = [
      SELECT COUNT()
      FROM Partner_Document_Requirement__c
      WHERE
        Onboarding__c = :onboardingId
        AND Blocking__c = TRUE
        AND Status__c != 'Accepted'
      WITH SYSTEM_MODE
    ];
    put(
      result,
      'documents',
      (documentTotal > 0 && documentOpen == 0) ||
      waivedGates.contains('documents'),
      'Mandatory documents are incomplete.'
    );
    Integer openFindings = [
      SELECT COUNT()
      FROM Partner_Assessment_Finding__c
      WHERE
        Assessment__r.Onboarding__c = :onboardingId
        AND Blocking__c = TRUE
        AND Status__c = 'Open'
      WITH SYSTEM_MODE
    ];
    put(
      result,
      'risk',
      openFindings == 0 || waivedGates.contains('risk'),
      'Blocking risk findings remain open.'
    );
    put(
      result,
      'approval',
      [
        SELECT COUNT()
        FROM Partner_Approval_Plan__c
        WHERE
          Onboarding__c = :onboardingId
          AND Current__c = TRUE
          AND Status__c = 'Approved for Contracting'
        WITH SYSTEM_MODE
      ] == 1 || waivedGates.contains('approval'),
      'Final approval is incomplete.'
    );
    put(
      result,
      'agreements',
      [
        SELECT COUNT()
        FROM Partner_Agreement__c
        WHERE Onboarding__c = :onboardingId AND Status__c = 'Effective'
        WITH SYSTEM_MODE
      ] > 0 || waivedGates.contains('agreements'),
      'Required agreement is not effective.'
    );
    Boolean partnerEnabled =
      [
        SELECT COUNT()
        FROM Partner_Relationship__c
        WHERE
          Onboarding__c = :onboardingId
          AND Status__c = 'Active'
          AND Account__r.IsPartner = TRUE
        WITH SYSTEM_MODE
      ] > 0;
    partnerEnabled =
      partnerEnabled || (Test.isRunningTest() && testAccountPartnerEnabled);
    put(
      result,
      'relationship',
      partnerEnabled || waivedGates.contains('relationship'),
      'Partner relationship or Salesforce partner enablement is incomplete.'
    );
    put(
      result,
      'access',
      [
        SELECT COUNT()
        FROM Partner_Access_Request__c
        WHERE Onboarding__c = :onboardingId AND Status__c = 'Provisioned'
        WITH SYSTEM_MODE
      ] > 0 || waivedGates.contains('access'),
      'Approved access has not been provisioned.'
    );
    Integer trainingTotal = [
      SELECT COUNT()
      FROM Partner_Training_Assignment__c
      WHERE Onboarding__c = :onboardingId AND Mandatory__c = TRUE
      WITH SYSTEM_MODE
    ];
    Integer trainingOpen = [
      SELECT COUNT()
      FROM Partner_Training_Assignment__c
      WHERE
        Onboarding__c = :onboardingId
        AND Mandatory__c = TRUE
        AND Status__c != 'Completed'
      WITH SYSTEM_MODE
    ];
    put(
      result,
      'training',
      (trainingTotal > 0 && trainingOpen == 0) ||
      waivedGates.contains('training'),
      'Mandatory training is incomplete.'
    );
    result.ready = result.blockers.isEmpty();

    Partner_Assessment__c readiness = new Partner_Assessment__c(
      Onboarding__c = onboardingId,
      Assessment_Key__c = onboardingId + ':Readiness',
      Assessment_Type__c = 'Readiness',
      Status__c = result.ready ? 'Passed' : 'Failed',
      Blocking__c = true,
      Outcome_Reason__c = String.join(result.blockers, '\n'),
      Assessed_By__c = UserInfo.getUserId(),
      Assessed_On__c = System.now()
    );
    Database.upsert(
      readiness,
      Partner_Assessment__c.Fields.Assessment_Key__c,
      AccessLevel.SYSTEM_MODE
    );
    onboarding.Activation_Gate_Status__c = result.ready ? 'Ready' : 'Blocked';
    onboarding.Current_Stage__c = 'Readiness';
    onboarding.Gate_Summary__c = JSON.serialize(result.gates);
    Database.update(onboarding, AccessLevel.SYSTEM_MODE);
    return result;
  }

  /**
   * Activates an onboarding that has a persisted Ready gate evaluation,
   * setting hypercare and recertification dates and recording a lifecycle
   * event. Requires partner lifecycle management authority.
   *
   * @param onboardingId Id of the Partner_Onboarding__c to activate.
   * @return The updated, now-Active Partner_Onboarding__c record.
   */
  public static Partner_Onboarding__c activate(Id onboardingId) {
    assertLifecycleAuthority();
    Partner_Onboarding__c onboarding = [
      SELECT Id, Status__c, Activation_Gate_Status__c, Version_Number__c
      FROM Partner_Onboarding__c
      WHERE Id = :onboardingId
      WITH SYSTEM_MODE
      LIMIT 1
      FOR UPDATE
    ];
    if (
      onboarding.Status__c != 'Onboarding' ||
      onboarding.Activation_Gate_Status__c != 'Ready'
    ) {
      throw new LifecycleException(
        'A persisted Ready evaluation is required before activation.'
      );
    }
    onboarding.Status__c = 'Active';
    onboarding.Current_Stage__c = 'Active';
    onboarding.Activated_On__c = System.now();
    onboarding.Hypercare_Ends_On__c = Date.today().addDays(60);
    onboarding.Recertification_Due_On__c = Date.today().addYears(1);
    onboarding.Version_Number__c = onboarding.Version_Number__c + 1;
    Database.update(onboarding, AccessLevel.SYSTEM_MODE);
    recordEvent(
      onboarding,
      'Partner Activated',
      'Partner passed all activation gates.'
    );
    return onboarding;
  }

  /**
   * Transitions an onboarding to a post-activation lifecycle status
   * (Suspended, Under Investigation, Termination Pending, Terminated, or
   * Archived), recording the reason and, for Terminated, expiring related
   * relationships and access requests. Requires partner lifecycle
   * management authority.
   *
   * @param onboardingId Id of the Partner_Onboarding__c to transition.
   * @param targetStatus The lifecycle status to transition to.
   * @param reason Reason for the transition.
   * @return The updated Partner_Onboarding__c record.
   */
  public static Partner_Onboarding__c transition(
    Id onboardingId,
    String targetStatus,
    String reason
  ) {
    assertLifecycleAuthority();
    if (
      !new Set<String>{
          'Suspended',
          'Under Investigation',
          'Termination Pending',
          'Terminated',
          'Archived'
        }
        .contains(targetStatus) || String.isBlank(reason)
    ) {
      throw new IllegalArgumentException(
        'Supported lifecycle status and reason are required.'
      );
    }
    Partner_Onboarding__c onboarding = [
      SELECT Id, Status__c, Current_Stage__c, Version_Number__c
      FROM Partner_Onboarding__c
      WHERE Id = :onboardingId
      WITH SYSTEM_MODE
      LIMIT 1
      FOR UPDATE
    ];
    onboarding.Status__c = targetStatus;
    onboarding.Lifecycle_Reason__c = reason;
    onboarding.Version_Number__c = onboarding.Version_Number__c + 1;
    Database.update(onboarding, AccessLevel.SYSTEM_MODE);
    if (targetStatus == 'Terminated') {
      List<Partner_Relationship__c> relationships = [
        SELECT Id
        FROM Partner_Relationship__c
        WHERE Onboarding__c = :onboardingId
        WITH SYSTEM_MODE
      ];
      for (Partner_Relationship__c relationship : relationships)
        relationship.Status__c = 'Terminated';
      Database.update(relationships, AccessLevel.SYSTEM_MODE);
      List<Partner_Access_Request__c> requests = [
        SELECT Id
        FROM Partner_Access_Request__c
        WHERE Onboarding__c = :onboardingId AND Status__c != 'Expired'
        WITH SYSTEM_MODE
      ];
      for (Partner_Access_Request__c request : requests)
        request.Status__c = 'Expired';
      Database.update(requests, AccessLevel.SYSTEM_MODE);
    }
    recordEvent(onboarding, 'Partner ' + targetStatus, reason);
    return onboarding;
  }

  private static void put(
    GateResult result,
    String key,
    Boolean passed,
    String blocker
  ) {
    result.gates.put(key, passed);
    if (!passed)
      result.blockers.add(blocker);
  }

  private static void assertLifecycleAuthority() {
    if (
      !FeatureManagement.checkPermission(
        'PartnerSync_Manage_Partner_Lifecycle'
      ) && !(Test.isRunningTest() && testLifecycleAuthority)
    ) {
      throw new LifecycleException('Partner lifecycle authority is required.');
    }
  }

  private static void recordEvent(
    Partner_Onboarding__c onboarding,
    String eventType,
    String summary
  ) {
    Database.insert(
      new Partner_Lifecycle_Event__c(
        Onboarding__c = onboarding.Id,
        Event_Type__c = eventType,
        Stage__c = onboarding.Current_Stage__c,
        Summary__c = summary,
        Occurred_On__c = System.now(),
        Actor__c = UserInfo.getUserId(),
        Idempotency_Key__c = onboarding.Id +
          ':' +
          eventType +
          ':' +
          onboarding.Version_Number__c
      ),
      AccessLevel.SYSTEM_MODE
    );
  }

  /**
   * Thrown when a partner lifecycle operation is attempted without
   * required authority or against an onboarding in an invalid state.
   */
  public class LifecycleException extends Exception {
  }
}
