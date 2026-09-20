@IsTest
private class MDFSelectorTest {
  @IsTest
  static void internalAdminExercisesEverySelectorAndGuard() {
    User adminUser = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSet(
      adminUser.Id,
      'PartnerSync_Internal_Admin'
    );
    System.runAs(adminUser) {
      Account partner = PartnerSyncTestDataFactory.partnerAccount('Partner');
      partner.MDF_Annual_Budget__c = 10000;
      partner.MDF_Used__c = 1000;
      insert partner;
      MDF_Request__c request = new MDF_Request__c(
        Partner_Account__c = partner.Id,
        Campaign_Name__c = 'Campaign',
        Campaign_Type__c = 'Webinar',
        Requested_Amount__c = 500,
        Status__c = 'Submitted'
      );
      insert request;

      Assert.areEqual(1, MDFSelector.selectMyRequests(partner.Id).size());
      Assert.areEqual(1, MDFSelector.selectReviewQueue().size());
      Assert.areEqual(
        partner.Id,
        MDFSelector.selectPartnerBudget(partner.Id).Id
      );
      Assert.areEqual(
        request.Id,
        MDFSelector.selectForPartner(request.Id, partner.Id).Id
      );
      Assert.areEqual(
        request.Id,
        MDFSelector.selectForInternalReview(request.Id).Id
      );
      Assert.areEqual(request.Id, MDFSelector.selectForDecision(request.Id).Id);
      Assert.areEqual(
        1000,
        MDFSelector.selectPartnerBudgetForApproval(partner.Id).MDF_Used__c
      );
      try {
        MDFSelector.selectForDecision(partner.Id);
        Assert.fail('Expected missing locked request rejection.');
      } catch (PartnerSyncHandledException expected) {
        Assert.isTrue(expected.getMessage().contains('not found'));
      }
      try {
        MDFSelector.selectPartnerBudgetForApproval(UserInfo.getUserId());
        Assert.fail('Expected missing locked budget rejection.');
      } catch (PartnerSyncHandledException expected) {
        Assert.isTrue(expected.getMessage().contains('not found'));
      }
      assertNotAccessible(request.Id, UserInfo.getUserId());
      assertBudgetMissing(UserInfo.getUserId());
      assertInternalMissing(partner.Id);
    }
  }

  private static void assertNotAccessible(Id requestId, Id partnerId) {
    try {
      MDFSelector.selectForPartner(requestId, partnerId);
      Assert.fail('Expected inaccessible request rejection.');
    } catch (PartnerSyncHandledException expected) {
      Assert.isTrue(expected.getMessage().contains('not accessible'));
    }
  }

  private static void assertBudgetMissing(Id accountId) {
    try {
      MDFSelector.selectPartnerBudget(accountId);
      Assert.fail('Expected missing partner rejection.');
    } catch (PartnerSyncHandledException expected) {
      Assert.isTrue(expected.getMessage().contains('not found'));
    }
  }

  private static void assertInternalMissing(Id requestId) {
    try {
      MDFSelector.selectForInternalReview(requestId);
      Assert.fail('Expected missing request rejection.');
    } catch (PartnerSyncHandledException expected) {
      Assert.isTrue(expected.getMessage().contains('not found'));
    }
  }
}
