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
