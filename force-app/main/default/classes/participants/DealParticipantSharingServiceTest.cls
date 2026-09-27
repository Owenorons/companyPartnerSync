/*
 * Covers DealParticipantSharingService's desired-state reconciliation:
 * an Active, non-originating co-sell participant gets a Co-Sell-reason
 * Apex Managed Share; a suspended/removed one loses it; an Internal Only
 * participant gets none; and reconciliation never touches a manually
 * granted share under a different Share_Reason__c.
 */
@IsTest
private class DealParticipantSharingServiceTest {
  @IsTest
  static void activeParticipantGetsAccessMaterialized() {
    Fixture fixture = createFixture();

    System.runAs(fixture.manager) {
      insert activeParticipant(
        fixture.deal.Id,
        fixture.coSellPartner.Id,
        'Collaborator'
      );

      DealParticipantSharingService.reconcileForDeal(fixture.deal.Id);

      Assert.isTrue(
        PartnerShareSelector.hasActiveGrant(
          fixture.deal.Id,
          fixture.coSellPartner.Id
        )
      );
      Partner_Record_Share__c share = PartnerShareSelector.selectActiveSharesForRecord(
        fixture.deal.Id
      )[0];
      Assert.areEqual('Co-Sell', share.Share_Reason__c);
      Assert.areEqual('Edit', share.Access_Level__c);
    }
  }

  @IsTest
  static void removedParticipantLosesAccess() {
    Fixture fixture = createFixture();

    System.runAs(fixture.manager) {
      Deal_Participant__c participant = activeParticipant(
        fixture.deal.Id,
        fixture.coSellPartner.Id,
        'Collaborator'
      );
      insert participant;
      DealParticipantSharingService.reconcileForDeal(fixture.deal.Id);
      Assert.isTrue(
        PartnerShareSelector.hasActiveGrant(
          fixture.deal.Id,
          fixture.coSellPartner.Id
        )
      );

      participant.Status__c = 'Removed';
      update participant;
      DealParticipantSharingService.reconcileForDeal(fixture.deal.Id);

      Assert.isFalse(
        PartnerShareSelector.hasActiveGrant(
          fixture.deal.Id,
          fixture.coSellPartner.Id
        )
      );
    }
  }

  @IsTest
  static void internalOnlyParticipantReceivesNoCommercialAccess() {
    Fixture fixture = createFixture();

    System.runAs(fixture.manager) {
      insert activeParticipant(
        fixture.deal.Id,
        fixture.coSellPartner.Id,
        'Internal Only'
      );

      DealParticipantSharingService.reconcileForDeal(fixture.deal.Id);

      Assert.isFalse(
        PartnerShareSelector.hasActiveGrant(
          fixture.deal.Id,
          fixture.coSellPartner.Id
        )
      );
    }
  }

  @IsTest
  static void customerCreatedSharingIsNeverTouched() {
    Fixture fixture = createFixture();

    System.runAs(fixture.manager) {
      PartnerShareDTO manualGrant = new PartnerShareDTO();
      manualGrant.targetRecordId = fixture.deal.Id;
      manualGrant.targetObject = 'Deal Registration';
      manualGrant.partnerAccountId = fixture.coSellPartner.Id;
      manualGrant.accessLevel = 'Read';
      manualGrant.shareReason = 'Escalation';
      Id manualShareId = PartnerShareService.grantAccess(manualGrant);

      // No active Deal_Participant__c exists for this partner at all -
      // reconciliation should still leave the manually-granted,
      // non-Co-Sell-reason share alone.
      DealParticipantSharingService.reconcileForDeal(fixture.deal.Id);

      Assert.isTrue(
        PartnerShareSelector.hasActiveGrant(
          fixture.deal.Id,
          fixture.coSellPartner.Id
        )
      );
      Assert.areEqual(
        'Escalation',
        [
          SELECT Share_Reason__c
          FROM Partner_Record_Share__c
          WHERE Id = :manualShareId
        ]
        .Share_Reason__c
      );
    }
  }

  private static Deal_Participant__c activeParticipant(
    Id dealId,
    Id partnerAccountId,
    String accessLevel
  ) {
    return new Deal_Participant__c(
      Deal__c = dealId,
      Partner_Account__c = partnerAccountId,
      Participant_Type__c = 'Co-Sell Partner',
      Participant_Role__c = 'Co-Sell Contributor',
      Status__c = 'Active',
      Access_Level__c = accessLevel,
      Active_Participant_Key__c = dealId +
        '|Co-Sell Partner|' +
        partnerAccountId +
        '|Co-Sell Contributor',
      Version_Number__c = 0
    );
  }

  // Proves the doc's full 200-record bulk requirement (§38.50): reconciling
  // 200 brand-new grants for one deal in a single transaction, via
  // PartnerShareService.grantParticipantAccessBulk's batched SOQL/DML
  // rather than the one-query-and-one-DML-per-grant shape the interactive
  // grantAccess()/grantParticipantAccess() entry points use.
  @IsTest
  static void reconciliationHandles200NewGrantsWithinGovernorLimits() {
    Fixture fixture = createFixture();
    Group partnerGroup = [
      SELECT Id
      FROM Group
      WHERE DeveloperName = 'Deal_Participant_Sharing_Test_Group'
      LIMIT 1
    ];

    List<Account> coSellPartners = new List<Account>();
    for (Integer i = 0; i < 200; i++) {
      coSellPartners.add(
        PartnerSyncTestDataFactory.partnerAccount('Bulk Co-Sell Partner ' + i)
      );
    }
    insert coSellPartners;

    List<Partner_Access_Group__c> groupMappings = new List<Partner_Access_Group__c>();
    List<Deal_Participant__c> participants = new List<Deal_Participant__c>();
    for (Account partner : coSellPartners) {
      groupMappings.add(
        new Partner_Access_Group__c(
          Partner_Account__c = partner.Id,
          Group_Id__c = String.valueOf(partnerGroup.Id),
          Active__c = true
        )
      );
      participants.add(
        activeParticipant(fixture.deal.Id, partner.Id, 'Collaborator')
      );
    }
    insert groupMappings;
    insert participants;

    System.runAs(fixture.manager) {
      Test.startTest();
      DealParticipantSharingService.reconcileForDeal(fixture.deal.Id);
      Test.stopTest();
    }

    Assert.areEqual(
      200,
      [
        SELECT COUNT()
        FROM Partner_Record_Share__c
        WHERE
          Target_Record_Id__c = :String.valueOf(fixture.deal.Id)
          AND Active__c = TRUE
      ]
    );
  }

  // Proves the revoke side is equally bulk-safe: 200 previously-granted
  // shares all losing access (e.g. every co-sell participant suspended at
  // once) in a single reconcileForDeal() call.
  @IsTest
  static void reconciliationHandles200RevocationsWithinGovernorLimits() {
    Fixture fixture = createFixture();
    Group partnerGroup = [
      SELECT Id
      FROM Group
      WHERE DeveloperName = 'Deal_Participant_Sharing_Test_Group'
      LIMIT 1
    ];

    List<Account> coSellPartners = new List<Account>();
    for (Integer i = 0; i < 200; i++) {
      coSellPartners.add(
        PartnerSyncTestDataFactory.partnerAccount('Revoke Co-Sell Partner ' + i)
      );
    }
    insert coSellPartners;

    List<Partner_Access_Group__c> groupMappings = new List<Partner_Access_Group__c>();
    List<Deal_Participant__c> participants = new List<Deal_Participant__c>();
    for (Account partner : coSellPartners) {
      groupMappings.add(
        new Partner_Access_Group__c(
          Partner_Account__c = partner.Id,
          Group_Id__c = String.valueOf(partnerGroup.Id),
          Active__c = true
        )
      );
      participants.add(
        activeParticipant(fixture.deal.Id, partner.Id, 'Collaborator')
      );
    }
    insert groupMappings;
    insert participants;

    System.runAs(fixture.manager) {
      DealParticipantSharingService.reconcileForDeal(fixture.deal.Id);
    }
    Assert.areEqual(
      200,
      [
        SELECT COUNT()
        FROM Partner_Record_Share__c
        WHERE
          Target_Record_Id__c = :String.valueOf(fixture.deal.Id)
          AND Active__c = TRUE
      ]
    );

    for (Deal_Participant__c participant : participants) {
      participant.Status__c = 'Suspended';
    }
    update participants;

    System.runAs(fixture.manager) {
      Test.startTest();
      DealParticipantSharingService.reconcileForDeal(fixture.deal.Id);
      Test.stopTest();
    }

    Assert.areEqual(
      0,
      [
        SELECT COUNT()
        FROM Partner_Record_Share__c
        WHERE
          Target_Record_Id__c = :String.valueOf(fixture.deal.Id)
          AND Active__c = TRUE
      ]
    );
  }

  private static Fixture createFixture() {
    Fixture fixture = new Fixture();
    fixture.manager = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSetGroup(
      fixture.manager.Id,
      'PSG_Internal_Administrator'
    );

    Group partnerGroup = new Group(
      Name = 'Deal Participant Sharing Test Group',
      DeveloperName = 'Deal_Participant_Sharing_Test_Group',
      Type = 'Regular'
    );
    insert partnerGroup;

    fixture.originatingPartner = PartnerSyncTestDataFactory.partnerAccount(
      'Originating Partner'
    );
    fixture.coSellPartner = PartnerSyncTestDataFactory.partnerAccount(
      'Co-Sell Partner'
    );
    Account customer = PartnerSyncTestDataFactory.customerAccount(
      'Sharing Customer'
    );
    insert new List<Account>{
      fixture.originatingPartner,
      fixture.coSellPartner,
      customer
    };
    insert new Partner_Access_Group__c(
      Partner_Account__c = fixture.coSellPartner.Id,
      Group_Id__c = String.valueOf(partnerGroup.Id),
      Active__c = true
    );

    fixture.deal = PartnerSyncTestDataFactory.deal(
      customer.Id,
      fixture.originatingPartner.Id,
      null,
      null
    );
    fixture.deal.Status__c = 'Approved';
    insert fixture.deal;

    return fixture;
  }

  private class Fixture {
    User manager;
    Account originatingPartner;
    Account coSellPartner;
    Deal_Registration__c deal;
  }
}
