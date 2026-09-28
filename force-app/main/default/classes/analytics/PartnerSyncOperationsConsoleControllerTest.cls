/*
 * Covers PartnerSyncOperationsConsoleController: an internal user sees the
 * real dead-letter and AI health counts from a fixture in each state, retry/
 * acknowledge actions reach EventDLQService, and an external partner user is
 * rejected from every method.
 */
@IsTest
private class PartnerSyncOperationsConsoleControllerTest {
  @IsTest
  static void healthReflectsRealFixtureRowsInEachState() {
    Fixture fixture = createFixture();
    User internalUser = TestUserFactory.createInternalUser();

    OperationsHealthDTO health;
    System.runAs(internalUser) {
      health = PartnerSyncOperationsConsoleController.getOperationsHealth();
    }

    Assert.areEqual(1, health.newDeadLetterCount);
    Assert.areEqual(1, health.failedDeadLetterCount);
    Assert.areEqual(1, health.retriedDeadLetterCount);
    Assert.areEqual(
      2,
      health.deadLetters.size(),
      'Only New/Failed rows should be listed, not Retried/Resolved.'
    );
    Assert.areEqual(1, health.aiFailedInteractionCount);
    Assert.areEqual(1, health.aiBlockedInteractionCount);
    Assert.areEqual(1, health.aiProposedRecommendationCount);
    Assert.areEqual(1, health.aiFailedRecommendationCount);
  }

  @IsTest
  static void retryDeadLetterReachesEventDLQService() {
    Fixture fixture = createFixture();
    User internalUser = TestUserFactory.createInternalUser();

    System.runAs(internalUser) {
      PartnerSyncOperationsConsoleController.retryDeadLetter(
        fixture.newDeadLetter.Id
      );
    }

    Event_DLQ__c reloaded = [
      SELECT Status__c, Retry_Count__c
      FROM Event_DLQ__c
      WHERE Id = :fixture.newDeadLetter.Id
    ];
    Assert.areEqual(1, reloaded.Retry_Count__c);
  }

  @IsTest
  static void acknowledgeDeadLetterReachesEventDLQService() {
    Fixture fixture = createFixture();
    User internalUser = TestUserFactory.createInternalUser();

    System.runAs(internalUser) {
      PartnerSyncOperationsConsoleController.acknowledgeDeadLetter(
        fixture.newDeadLetter.Id
      );
    }

    Event_DLQ__c reloaded = [
      SELECT Status__c
      FROM Event_DLQ__c
      WHERE Id = :fixture.newDeadLetter.Id
    ];
    Assert.areEqual('Resolved', reloaded.Status__c);
  }

  @IsTest
  static void externalPartnerUserIsRejectedFromEveryMethod() {
    Fixture fixture = createFixture();
    User partnerUser = TestUserFactory.createExternalUser(fixture.contact.Id);

    System.runAs(partnerUser) {
      try {
        PartnerSyncOperationsConsoleController.getOperationsHealth();
        Assert.fail('Expected an external partner user to be rejected.');
      } catch (AuraHandledException expected) {
        Assert.isTrue(true);
      }

      try {
        PartnerSyncOperationsConsoleController.retryDeadLetter(
          fixture.newDeadLetter.Id
        );
        Assert.fail('Expected an external partner user to be rejected.');
      } catch (AuraHandledException expected) {
        Assert.isTrue(true);
      }

      try {
        PartnerSyncOperationsConsoleController.acknowledgeDeadLetter(
          fixture.newDeadLetter.Id
        );
        Assert.fail('Expected an external partner user to be rejected.');
      } catch (AuraHandledException expected) {
        Assert.isTrue(true);
      }
    }
  }

  private static Fixture createFixture() {
    Fixture fixture = new Fixture();
    Account partner = PartnerSyncTestDataFactory.partnerAccount(
      'Operations Console Partner'
    );
    insert partner;
    fixture.contact = PartnerSyncTestDataFactory.partnerContact(partner.Id);
    insert fixture.contact;

    fixture.newDeadLetter = new Event_DLQ__c(
      Event_Type__c = 'TestEventType',
      Payload__c = '{}',
      Error_Message__c = 'First failure.',
      Retry_Count__c = 0,
      Status__c = 'New'
    );
    insert fixture.newDeadLetter;

    insert new Event_DLQ__c(
      Event_Type__c = 'TestEventType',
      Payload__c = '{}',
      Error_Message__c = 'Repeat failure.',
      Retry_Count__c = 2,
      Status__c = 'Failed'
    );
    insert new Event_DLQ__c(
      Event_Type__c = 'TestEventType',
      Payload__c = '{}',
      Retry_Count__c = 1,
      Status__c = 'Retried'
    );

    AI_Interaction__c succeeded = new AI_Interaction__c(
      Use_Case_Key__c = 'PortfolioNarrative',
      Status__c = 'Succeeded'
    );
    AI_Interaction__c failed = new AI_Interaction__c(
      Use_Case_Key__c = 'PortfolioNarrative',
      Status__c = 'Failed'
    );
    AI_Interaction__c blocked = new AI_Interaction__c(
      Use_Case_Key__c = 'PortfolioNarrative',
      Status__c = 'Blocked-Quota'
    );
    insert new List<AI_Interaction__c>{ succeeded, failed, blocked };

    insert new AI_Recommendation__c(
      Interaction__c = succeeded.Id,
      Recommended_Action_Key__c = 'RequestRenewalReview',
      Recommendation_Text__c = 'Proposed recommendation.',
      Status__c = 'Proposed'
    );
    insert new AI_Recommendation__c(
      Interaction__c = succeeded.Id,
      Recommended_Action_Key__c = 'RequestRenewalReview',
      Recommendation_Text__c = 'Failed recommendation.',
      Status__c = 'Failed'
    );

    return fixture;
  }

  private class Fixture {
    Contact contact;
    Event_DLQ__c newDeadLetter;
  }
}
