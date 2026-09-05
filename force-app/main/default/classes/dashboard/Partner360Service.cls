public without sharing class Partner360Service {
  public static Partner360DTO getSummary(Id partnerAccountId) {
    PartnerAccessService.assertInternalUser();
    if (partnerAccountId == null)
      throw new PartnerSyncHandledException('Partner account is required.');

    List<Account> accounts = [
      SELECT
        Id,
        Name,
        Partner_ID__c,
        Partner_Type__c,
        Partner_Tier__c,
        Partner_Region__c,
        Partner_Status__c
      FROM Account
      WHERE
        Id = :partnerAccountId
        AND (Is_Partner__c = TRUE
        OR IsPartner = TRUE)
      WITH SYSTEM_MODE
      LIMIT 1
    ];
    if (accounts.isEmpty())
      throw new PartnerSyncHandledException('Partner account not found.');

    Account partner = accounts[0];
    Partner360DTO dto = new Partner360DTO();
    dto.partnerAccountId = partner.Id;
    dto.partnerName = partner.Name;
    dto.partnerId = partner.Partner_ID__c;
    dto.partnerType = partner.Partner_Type__c;
    dto.tier = partner.Partner_Tier__c;
    dto.region = partner.Partner_Region__c;
    dto.partnerStatus = partner.Partner_Status__c;
    dto.blockers = new List<String>();
    dto.recentEvents = new List<Partner360EventDTO>();

    List<Partner_Onboarding__c> onboardings = [
      SELECT
        Id,
        Status__c,
        Current_Stage__c,
        Activation_Gate_Status__c,
        Recertification_Due_On__c
      FROM Partner_Onboarding__c
      WHERE Partner_Account__c = :partnerAccountId
      WITH SYSTEM_MODE
      ORDER BY CreatedDate DESC
      LIMIT 1
    ];
    if (!onboardings.isEmpty())
      populateOnboarding(dto, onboardings[0]);
    populateCommercialCounts(dto, partnerAccountId);
    return dto;
  }

  private static void populateOnboarding(
    Partner360DTO dto,
    Partner_Onboarding__c onboarding
  ) {
    dto.onboardingId = onboarding.Id;
    dto.onboardingStatus = onboarding.Status__c;
    dto.currentStage = onboarding.Current_Stage__c;
    dto.activationGateStatus = onboarding.Activation_Gate_Status__c;
    dto.recertificationDueOn = onboarding.Recertification_Due_On__c;

    List<Partner_Relationship__c> relationships = [
      SELECT Status__c, Programme_Key__c
      FROM Partner_Relationship__c
      WHERE Onboarding__c = :onboarding.Id
      WITH SYSTEM_MODE
      ORDER BY CreatedDate DESC
      LIMIT 1
    ];
    if (!relationships.isEmpty()) {
      dto.relationshipStatus = relationships[0].Status__c;
      dto.programmeKey = relationships[0].Programme_Key__c;
    }
    dto.openDocumentCount = [
      SELECT COUNT()
      FROM Partner_Document_Requirement__c
      WHERE
        Onboarding__c = :onboarding.Id
        AND Blocking__c = TRUE
        AND Status__c != 'Accepted'
      WITH SYSTEM_MODE
    ];
    dto.blockingFindingCount = [
      SELECT COUNT()
      FROM Partner_Assessment_Finding__c
      WHERE
        Assessment__r.Onboarding__c = :onboarding.Id
        AND Blocking__c = TRUE
        AND Status__c = 'Open'
      WITH SYSTEM_MODE
    ];
    dto.effectiveAgreementCount = [
      SELECT COUNT()
      FROM Partner_Agreement__c
      WHERE Onboarding__c = :onboarding.Id AND Status__c = 'Effective'
      WITH SYSTEM_MODE
    ];
    dto.openAccessRequestCount = [
      SELECT COUNT()
      FROM Partner_Access_Request__c
      WHERE
        Onboarding__c = :onboarding.Id
        AND Status__c NOT IN ('Provisioned', 'Rejected', 'Expired')
      WITH SYSTEM_MODE
    ];
    dto.incompleteTrainingCount = [
      SELECT COUNT()
      FROM Partner_Training_Assignment__c
      WHERE
        Onboarding__c = :onboarding.Id
        AND Mandatory__c = TRUE
        AND Status__c != 'Completed'
      WITH SYSTEM_MODE
    ];

    addBlocker(dto, dto.openDocumentCount, 'mandatory documents');
    addBlocker(dto, dto.blockingFindingCount, 'blocking risk findings');
    addBlocker(dto, dto.openAccessRequestCount, 'open access requests');
    addBlocker(
      dto,
      dto.incompleteTrainingCount,
      'incomplete mandatory training'
    );
    for (Partner_Lifecycle_Event__c eventRecord : [
      SELECT Id, Event_Type__c, Stage__c, Summary__c, Occurred_On__c
      FROM Partner_Lifecycle_Event__c
      WHERE Onboarding__c = :onboarding.Id
      WITH SYSTEM_MODE
      ORDER BY Occurred_On__c DESC
      LIMIT 10
    ]) {
      Partner360EventDTO item = new Partner360EventDTO();
      item.recordId = eventRecord.Id;
      item.eventType = eventRecord.Event_Type__c;
      item.stage = eventRecord.Stage__c;
      item.summary = eventRecord.Summary__c;
      item.occurredOn = eventRecord.Occurred_On__c;
      dto.recentEvents.add(item);
    }
  }

  private static void populateCommercialCounts(
    Partner360DTO dto,
    Id accountId
  ) {
    dto.openDealCount = [
      SELECT COUNT()
      FROM Deal_Registration__c
      WHERE
        Partner_Account__c = :accountId
        AND Status__c NOT IN ('Rejected', 'Expired', 'Cancelled')
      WITH SYSTEM_MODE
    ];
    dto.openMdfCount = [
      SELECT COUNT()
      FROM MDF_Request__c
      WHERE
        Partner_Account__c = :accountId
        AND Status__c IN ('Submitted', 'Under Review')
      WITH SYSTEM_MODE
    ];
  }

  private static void addBlocker(
    Partner360DTO dto,
    Integer count,
    String label
  ) {
    if (count > 0)
      dto.blockers.add(count + ' ' + label);
  }
}
