/** Persists individual activation gates and controls post-onboarding lifecycle state. */
public without sharing class PartnerReadinessLifecycleService {
  @TestVisible
  private static Boolean testAccountPartnerEnabled = false;
  @TestVisible
  private static Boolean testLifecycleAuthority = false;

  public class GateResult {
    @AuraEnabled
    public Boolean ready;
    @AuraEnabled
    public Map<String, Boolean> gates = new Map<String, Boolean>();
    @AuraEnabled
    public List<String> blockers = new List<String>();
  }

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
      documentTotal > 0 && documentOpen == 0,
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
      openFindings == 0,
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
      ] == 1,
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
      ] > 0,
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
      partnerEnabled,
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
      ] > 0,
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
      trainingTotal > 0 && trainingOpen == 0,
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

  public class LifecycleException extends Exception {
  }
}
