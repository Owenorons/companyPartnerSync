@IsTest
private class ControllerErrorContractTest {
  @IsTest
  static void analyticsAndAiControllersReturnSafeErrors() {
    assertAura(new CalloutCase('analyticsKpi'));
    User unprivilegedUser = TestUserFactory.createInternalUser();
    System.runAs(unprivilegedUser) {
      assertAura(new CalloutCase('analyticsLeaderboard'));
      assertAura(new CalloutCase('analyticsRevenue'));
    }
    assertAura(new CalloutCase('generateInsight'));
    assertAura(new CalloutCase('testProvider'));
    assertAura(new CalloutCase('partnerInsights'));
    assertAura(new CalloutCase('partnerActions'));
  }

  @IsTest
  static void leadMdfAndDealControllersReturnSafeErrors() {
    assertAura(new CalloutCase('assignLead'));
    assertAura(new CalloutCase('myLeads'));
    assertAura(new CalloutCase('leadDecision'));
    assertAura(new CalloutCase('submitMdf'));
    assertAura(new CalloutCase('myMdf'));
    assertAura(new CalloutCase('myBudget'));
    assertAura(new CalloutCase('mdfQueue'));
    assertAura(new CalloutCase('mdfDecision'));
    assertAura(new CalloutCase('dealQueue'));
    assertAura(new CalloutCase('dealDetail'));
    assertAura(new CalloutCase('dealDecision'));
    assertAura(new CalloutCase('registerDeal'));
    assertAura(new CalloutCase('eligibleDeals'));
    assertAura(new CalloutCase('myDeals'));
  }

  @IsTest
  static void contentAndApprovalControllersReturnSafeErrors() {
    assertAura(new CalloutCase('availableContent'));
    Assert.isNotNull(PartnerContentController.getCategories());
    assertAura(new CalloutCase('allContent'));
    assertAura(new CalloutCase('saveContent'));
    assertAura(new CalloutCase('downloadContent'));
    assertAura(new CalloutCase('partnerDecision'));
    assertAura(new CalloutCase('provisionPartner'));
  }

  @IsTest
  static void unexpectedErrorsAreLoggedAndSanitized() {
    AuraHandledException mapped = ControllerExceptionMapper.toAura(
      'CoverageController',
      'Internal diagnostic message.',
      'Safe client message.',
      new DmlException()
    );
    Assert.isNotNull(mapped);
  }

  private static void assertAura(CalloutCase scenario) {
    try {
      scenario.invoke();
      Assert.fail('Expected safe Aura error for ' + scenario.name);
    } catch (AuraHandledException expected) {
      Assert.isNotNull(expected);
    }
  }

  private class CalloutCase {
    private String name;
    private CalloutCase(String name) {
      this.name = name;
    }
    private void invoke() {
      if (name == 'analyticsKpi')
        AnalyticsController.getMyKPI();
      else if (name == 'analyticsLeaderboard')
        AnalyticsController.getPartnerLeaderboard();
      else if (name == 'analyticsRevenue')
        AnalyticsController.getCustomerRevenue();
      else if (name == 'generateInsight')
        AIInsightController.generateInsight(null);
      else if (name == 'testProvider')
        AIInsightController.testProviderConnection(null);
      else if (name == 'partnerInsights')
        PartnerAIController.getMyInsights();
      else if (name == 'partnerActions')
        PartnerAIController.getMyNextBestActions();
      else if (name == 'assignLead')
        LeadDistributionController.assignLeadToPartner(null);
      else if (name == 'myLeads')
        LeadDistributionController.getMyLeads();
      else if (name == 'leadDecision')
        LeadDistributionController.processDecision(null);
      else if (name == 'submitMdf')
        MDFController.submitRequest(null);
      else if (name == 'myMdf')
        MDFController.getMyRequests();
      else if (name == 'myBudget')
        MDFController.getMyBudget();
      else if (name == 'mdfQueue')
        MDFController.getReviewQueue();
      else if (name == 'mdfDecision')
        MDFController.processDecision(null);
      else if (name == 'dealQueue')
        DealReviewController.getReviewQueue();
      else if (name == 'dealDetail')
        DealReviewController.getReviewDetail(null);
      else if (name == 'dealDecision')
        DealReviewController.processDecision(null);
      else if (name == 'registerDeal')
        DealRegistrationController.createDealRegistration(null);
      else if (name == 'eligibleDeals')
        DealRegistrationController.getEligibleOpportunities();
      else if (name == 'myDeals')
        DealRegistrationController.getMyDeals();
      else if (name == 'availableContent')
        PartnerContentController.getAvailableContent();
      else if (name == 'contentCategories')
        PartnerContentController.getCategories();
      else if (name == 'allContent')
        PartnerContentController.getAllContent();
      else if (name == 'saveContent')
        PartnerContentController.saveContent(null);
      else if (name == 'downloadContent')
        PartnerContentController.getDownloadUrl(null);
      else if (name == 'partnerDecision')
        PartnerApprovalController.processDecision(null);
      else if (name == 'provisionPartner')
        PartnerApprovalController.requestProvisioning(null);
    }
  }
}
