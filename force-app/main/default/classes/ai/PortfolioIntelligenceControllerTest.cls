/*
 * Covers PortfolioIntelligenceController: an internal user with the
 * required permission sees portfolio snapshots, an external partner user
 * is rejected from the internal-only snapshot view entirely, and a
 * partner submitting feedback may only target a recommendation tied to
 * their own partner account - never another partner's.
 */
@IsTest
private class PortfolioIntelligenceControllerTest {
  @IsTest
  static void internalUserWithPermissionSeesSnapshots() {
    Fixture fixture = createFixture();
    User internalUser = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSet(
      internalUser.Id,
      'PartnerSync_Channel_Manager'
    );
    DealLifecyclePermissionService.setTestPermission(
      'PartnerSync_View_Portfolio_Intelligence',
      true
    );

    System.runAs(internalUser) {
      List<Partner_Portfolio_Snapshot__c> results = PortfolioIntelligenceController.getAllSnapshots();
      Assert.areEqual(1, results.size());
      Assert.areEqual(fixture.snapshot.Id, results[0].Id);
    }
  }

  @IsTest
  static void externalPartnerUserIsRejectedFromTheInternalOnlySnapshotView() {
    Fixture fixture = createFixture();
    User partnerUser = TestUserFactory.createExternalUser(fixture.contact.Id);

    System.runAs(partnerUser) {
      try {
        PortfolioIntelligenceController.getAllSnapshots();
        Assert.fail('Expected an external partner user to be rejected.');
      } catch (AuraHandledException expected) {
        Assert.isTrue(true);
      }
    }
  }

  @IsTest
  static void partnerCanSubmitFeedbackOnlyForTheirOwnPartnersRecommendation() {
    Fixture fixture = createFixture();
    Account otherPartner = PartnerSyncTestDataFactory.partnerAccount(
      'Unrelated Feedback Partner'
    );
    insert otherPartner;
    AI_Interaction__c otherInteraction = new AI_Interaction__c(
      Use_Case_Key__c = 'RenewalRiskAdvisor',
      Status__c = 'Succeeded'
    );
    insert otherInteraction;
    AI_Recommendation__c otherRecommendation = new AI_Recommendation__c(
      Interaction__c = otherInteraction.Id,
      Partner_Account__c = otherPartner.Id,
      Recommended_Action_Key__c = 'RequestRenewalReview',
      Recommendation_Text__c = 'For a different partner entirely.',
      Status__c = 'Proposed'
    );
    insert otherRecommendation;

    User partnerUser = TestUserFactory.createExternalUser(fixture.contact.Id);
    DealLifecyclePermissionService.setTestPermission(
      'PartnerSync_Submit_AI_Feedback',
      true
    );

    System.runAs(partnerUser) {
      AI_Feedback__c feedback = PortfolioIntelligenceController.submitFeedback(
        fixture.recommendation.Id,
        'Helpful',
        'Good call.'
      );
      Assert.isNotNull(feedback.Id);

      try {
        PortfolioIntelligenceController.submitFeedback(
          otherRecommendation.Id,
          'Helpful',
          'Trying to comment on a recommendation that is not mine.'
        );
        Assert.fail(
          'Expected feedback on another partner\'s recommendation to be rejected.'
        );
      } catch (AuraHandledException expected) {
        Assert.isTrue(true);
      }
    }
  }

  private static Fixture createFixture() {
    Fixture fixture = new Fixture();
    Account partner = PartnerSyncTestDataFactory.partnerAccount(
      'Portfolio Controller Partner'
    );
    insert partner;
    fixture.contact = PartnerSyncTestDataFactory.partnerContact(partner.Id);
    insert fixture.contact;

    fixture.snapshot = new Partner_Portfolio_Snapshot__c(
      Partner_Account__c = partner.Id,
      Snapshot_Date__c = Date.today(),
      Health_Score__c = 70,
      Health_Label__c = 'Healthy'
    );
    insert fixture.snapshot;

    AI_Interaction__c interaction = new AI_Interaction__c(
      Use_Case_Key__c = 'RenewalRiskAdvisor',
      Status__c = 'Succeeded'
    );
    insert interaction;
    fixture.recommendation = new AI_Recommendation__c(
      Interaction__c = interaction.Id,
      Partner_Account__c = partner.Id,
      Recommended_Action_Key__c = 'RequestRenewalReview',
      Recommendation_Text__c = 'Consider reviewing this renewal.',
      Status__c = 'Proposed'
    );
    insert fixture.recommendation;

    return fixture;
  }

  private class Fixture {
    Contact contact;
    Partner_Portfolio_Snapshot__c snapshot;
    AI_Recommendation__c recommendation;
  }
}
