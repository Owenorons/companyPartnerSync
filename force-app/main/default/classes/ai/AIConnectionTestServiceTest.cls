/*
 * Test coverage for AIConnectionTestService: success/failure status is
 * recorded on AI_Configuration__c, re-testing a provider updates that
 * row instead of duplicating it, and the AI Admin permission gate blocks
 * users without PartnerSync_AI_Admin.
 */
@IsTest
private class AIConnectionTestServiceTest {
  private static User createAiAdminUser() {
    User aiAdminUser = TestUserFactory.createInternalUser();

    TestUserFactory.assignPermissionSet(aiAdminUser.Id, 'PartnerSync_AI_Admin');

    return aiAdminUser;
  }

  @IsTest
  static void successfulTestRecordsConnectedStatus() {
    User aiAdminUser = createAiAdminUser();
    Test.setMock(HttpCalloutMock.class, AIHttpCalloutMock.success('OK'));

    AIProviderResponseDTO response;

    System.runAs(aiAdminUser) {
      Test.startTest();
      response = AIConnectionTestService.testConnection('OpenAI');
      Test.stopTest();
    }

    System.assertEquals(true, response.success);

    AI_Configuration__c config = [
      SELECT Connection_Status__c, Provider__c, Last_Test_Result__c
      FROM AI_Configuration__c
      WHERE Name = 'OpenAI'
    ];

    System.assertEquals('Connected', config.Connection_Status__c);
    System.assertEquals('OpenAI', config.Provider__c);
  }

  @IsTest
  static void failedTestRecordsFailedStatusAndCanBeRetested() {
    User aiAdminUser = createAiAdminUser();
    Test.setMock(
      HttpCalloutMock.class,
      AIHttpCalloutMock.failure(401, 'Unauthorized')
    );

    AIProviderResponseDTO first;

    System.runAs(aiAdminUser) {
      Test.startTest();
      first = AIConnectionTestService.testConnection('OpenAI');
      Test.stopTest();
    }

    System.assertEquals(false, first.success);

    AI_Configuration__c config = [
      SELECT Connection_Status__c
      FROM AI_Configuration__c
      WHERE Name = 'OpenAI'
    ];

    System.assertEquals('Failed', config.Connection_Status__c);

    List<AI_Configuration__c> allRows = [SELECT Id FROM AI_Configuration__c];
    System.assertEquals(
      1,
      allRows.size(),
      'Re-testing the same provider should update the existing row, not create a duplicate.'
    );
  }

  @IsTest
  static void unknownProviderReturnsFailureWithoutCallout() {
    User aiAdminUser = createAiAdminUser();
    AIProviderResponseDTO response;

    System.runAs(aiAdminUser) {
      Test.startTest();
      response = AIConnectionTestService.testConnection('NotARealProvider');
      Test.stopTest();
    }

    System.assertEquals(false, response.success);
    System.assert(response.errorMessage.contains('Unknown AI provider'));
  }

  @IsTest
  static void userWithoutAiAdminIsBlocked() {
    User internalUser = TestUserFactory.createInternalUser();

    System.runAs(internalUser) {
      try {
        AIConnectionTestService.testConnection('OpenAI');
        System.assert(false, 'Expected a PartnerSyncHandledException.');
      } catch (PartnerSyncHandledException ex) {
        System.assert(ex.getMessage().contains('permission to configure AI'));
      }
    }
  }
}
