@IsTest
private class AIServiceFlowTest {
  @IsTest
  static void partnerReadsInsightsAndPrioritizedActions() {
    Account partner = PartnerSyncTestDataFactory.partnerAccount('AI Partner');
    insert partner;
    Contact contact = PartnerSyncTestDataFactory.partnerContact(partner.Id);
    insert contact;
    User partnerUser = TestUserFactory.createExternalUser(contact.Id);
    TestUserFactory.assignPermissionSet(partnerUser.Id, 'PartnerSync_AI_User');

    List<AI_Insight__c> insights = new List<AI_Insight__c>();
    for (Integer index = 0; index < 6; index++) {
      AI_Insight__c insight = PartnerSyncTestDataFactory.insight(partner.Id);
      insight.OwnerId = partnerUser.Id;
      insight.Feature_Name__c = index == 1 ? null : 'Signal ' + index;
      insight.Confidence__c = index == 0
        ? 90
        : (index == 1 ? null : 40 + index);
      insight.Recommendation__c = index == 5 ? null : 'Action ' + index;
      insights.add(insight);
    }
    insert insights;

    System.runAs(partnerUser) {
      TenantConfigService.setConfigForTest(
        new Tenant_Config__mdt(Enable_AI__c = true)
      );
      List<AIInsightDTO> insightDtos = PartnerAIController.getMyInsights();
      Assert.areEqual(6, insightDtos.size());
      Assert.areEqual(
        insights[0].Id,
        AIInsightSelector.selectById(insights[0].Id).Id
      );
      List<NextBestActionDTO> actions = PartnerAIController.getMyNextBestActions();
      Assert.areEqual(5, actions.size());
      Assert.areEqual('High', actions[0].priority);
      Assert.areEqual('Recommended action', actions[1].title);
      Assert.areEqual('Medium', actions[1].priority);
      Assert.areEqual('Low', actions[2].priority);
    }
  }

  @IsTest
  static void eligibleOpportunityDtoExposesControllerContract() {
    EligibleOpportunityDTO dto = new EligibleOpportunityDTO();
    dto.opportunityId = UserInfo.getUserId();
    dto.name = 'Expansion';
    dto.stageName = 'Prospecting';
    dto.amount = 25000;
    dto.closeDate = Date.today();
    Assert.areEqual('Expansion', dto.name);
    Assert.areEqual(25000, dto.amount);
  }

  @IsTest
  static void aiAdministratorListsConfiguredProvidersAndStatus() {
    User administrator = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSetGroup(
      administrator.Id,
      'PSG_Internal_Administrator'
    );
    System.runAs(administrator) {
      insert new AI_Configuration__c(
        Provider__c = 'OpenAI',
        Connection_Status__c = 'Connected',
        Last_Test_Date__c = System.now(),
        Last_Test_Result__c = 'Success'
      );
      List<AIProviderStatusDTO> providers = AIInsightController.getProviders();
      Assert.isTrue(providers.size() > 0);
      Boolean foundConnected = false;
      Boolean foundUntested = false;
      for (AIProviderStatusDTO provider : providers) {
        if (provider.developerName == 'OpenAI') {
          foundConnected = provider.connectionStatus == 'Connected';
        } else if (provider.connectionStatus == 'Not Tested') {
          foundUntested = true;
        }
      }
      Assert.isTrue(foundConnected);
      Assert.isTrue(foundUntested);
    }
  }
}
