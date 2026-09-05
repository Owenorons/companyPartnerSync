/** Daily expiry and recertification enforcement for active partner relationships. */
public without sharing class PartnerLifecycleGovernanceBatch implements Database.Batchable<SObject>, Schedulable {
  public Database.QueryLocator start(Database.BatchableContext context) {
    return Database.getQueryLocator(
      [
        SELECT
          Id,
          Status__c,
          Current_Stage__c,
          Activation_Gate_Status__c,
          Recertification_Due_On__c,
          Version_Number__c
        FROM Partner_Onboarding__c
        WHERE Status__c NOT IN ('Closed', 'Terminated', 'Archived')
        WITH SYSTEM_MODE
      ]
    );
  }

  public void execute(
    Database.BatchableContext context,
    List<Partner_Onboarding__c> scope
  ) {
    Set<Id> onboardingIds = new Map<Id, Partner_Onboarding__c>(scope).keySet();
    Date today = Date.today();
    List<Partner_Agreement__c> agreements = [
      SELECT Id, Onboarding__c, Status__c
      FROM Partner_Agreement__c
      WHERE
        Onboarding__c IN :onboardingIds
        AND Status__c = 'Effective'
        AND Expires_On__c < :today
      WITH SYSTEM_MODE
    ];
    for (Partner_Agreement__c agreement : agreements)
      agreement.Status__c = 'Expired';
    Database.update(agreements, AccessLevel.SYSTEM_MODE);

    List<Partner_Access_Request__c> requests = [
      SELECT Id, Onboarding__c, Status__c
      FROM Partner_Access_Request__c
      WHERE
        Onboarding__c IN :onboardingIds
        AND Status__c IN ('Approved', 'Provisioning', 'Provisioned')
        AND Expires_On__c < :today
      WITH SYSTEM_MODE
    ];
    for (Partner_Access_Request__c request : requests)
      request.Status__c = 'Expired';
    Database.update(requests, AccessLevel.SYSTEM_MODE);

    List<Partner_Training_Assignment__c> training = [
      SELECT Id, Onboarding__c, Status__c
      FROM Partner_Training_Assignment__c
      WHERE
        Onboarding__c IN :onboardingIds
        AND Status__c = 'Completed'
        AND Expires_On__c < :today
      WITH SYSTEM_MODE
    ];
    for (Partner_Training_Assignment__c assignment : training)
      assignment.Status__c = 'Expired';
    Database.update(training, AccessLevel.SYSTEM_MODE);

    List<Partner_Document__c> documents = [
      SELECT Id, Onboarding__c, Requirement__c, Status__c
      FROM Partner_Document__c
      WHERE
        Onboarding__c IN :onboardingIds
        AND Status__c = 'Accepted'
        AND Superseded_By__c = NULL
        AND Expiry_Date__c < :today
      WITH SYSTEM_MODE
    ];
    Set<Id> expiredRequirementIds = new Set<Id>();
    for (Partner_Document__c document : documents) {
      document.Status__c = 'Expired';
      expiredRequirementIds.add(document.Requirement__c);
    }
    Database.update(documents, AccessLevel.SYSTEM_MODE);
    List<Partner_Document_Requirement__c> expiredRequirements = new List<Partner_Document_Requirement__c>();
    for (Id requirementId : expiredRequirementIds)
      expiredRequirements.add(
        new Partner_Document_Requirement__c(
          Id = requirementId,
          Status__c = 'Expired'
        )
      );
    Database.update(expiredRequirements, AccessLevel.SYSTEM_MODE);

    List<Partner_Lifecycle_Event__c> events = new List<Partner_Lifecycle_Event__c>();
    List<Partner_Onboarding__c> updates = new List<Partner_Onboarding__c>();
    Set<Id> expiredEvidence = new Set<Id>();
    for (Partner_Agreement__c agreement : agreements)
      expiredEvidence.add(agreement.Onboarding__c);
    for (Partner_Access_Request__c request : requests)
      expiredEvidence.add(request.Onboarding__c);
    for (Partner_Training_Assignment__c assignment : training)
      expiredEvidence.add(assignment.Onboarding__c);
    for (Partner_Document__c document : documents)
      expiredEvidence.add(document.Onboarding__c);

    for (Partner_Onboarding__c onboarding : scope) {
      Boolean recertificationDue =
        onboarding.Recertification_Due_On__c != null &&
        onboarding.Recertification_Due_On__c <= today;
      if (!recertificationDue && !expiredEvidence.contains(onboarding.Id))
        continue;
      onboarding.Activation_Gate_Status__c = 'Blocked';
      onboarding.Current_Stage__c = 'Readiness';
      onboarding.Lifecycle_Reason__c = recertificationDue
        ? 'Annual partner recertification is due.'
        : 'Time-bound activation evidence has expired.';
      onboarding.Version_Number__c = onboarding.Version_Number__c + 1;
      updates.add(onboarding);
      events.add(
        new Partner_Lifecycle_Event__c(
          Onboarding__c = onboarding.Id,
          Event_Type__c = recertificationDue
            ? 'Recertification Due'
            : 'Activation Evidence Expired',
          Stage__c = 'Readiness',
          Summary__c = onboarding.Lifecycle_Reason__c,
          Occurred_On__c = System.now(),
          Actor__c = UserInfo.getUserId(),
          Idempotency_Key__c = onboarding.Id +
            ':GOVERNANCE:' +
            String.valueOf(today)
        )
      );
    }
    Database.update(updates, AccessLevel.SYSTEM_MODE);
    Database.upsert(
      events,
      Partner_Lifecycle_Event__c.Fields.Idempotency_Key__c,
      AccessLevel.SYSTEM_MODE
    );
  }

  public void finish(Database.BatchableContext context) {
  }

  public void execute(SchedulableContext context) {
    Database.executeBatch(new PartnerLifecycleGovernanceBatch(), 100);
  }
}
