@IsTest
private class AIInsightRequestServiceTest {
  private static User partnerUser() {
    Account partner = PartnerSyncTestDataFactory.partnerAccount(
      'AI Request Partner'
    );
    insert partner;
    Contact contact = PartnerSyncTestDataFactory.partnerContact(partner.Id);
    insert contact;
    User result = TestUserFactory.createExternalUser(contact.Id);
    TestUserFactory.assignPermissionSet(result.Id, 'PartnerSync_Partner_User');
    return result;
  }

  @IsTest
  static void partnerSubmitsAndListsTheirOwnRequests() {
    User partner = partnerUser();
    System.runAs(partner) {
      AI_Insight_Request__c created = AIInsightRequestService.submitRequest(
        'LeadFitScoring',
        'Please assess our newest lead.'
      );
      Assert.isNotNull(created.Id);
      Assert.areEqual('New', created.Status__c);

      List<AI_Insight_Request__c> mine = AIInsightRequestService.getMyRequests();
      Assert.areEqual(1, mine.size());
      Assert.areEqual('Please assess our newest lead.', mine[0].Notes__c);
    }
  }

  @IsTest
  static void submitRequestRejectsDisabledOrUnknownFeature() {
    User partner = partnerUser();
    System.runAs(partner) {
      try {
        AIInsightRequestService.submitRequest('NotARealFeature', null);
        Assert.fail('Expected an unknown-feature rejection.');
      } catch (PartnerSyncHandledException expected) {
        Assert.isTrue(expected.getMessage().contains('not enabled'));
      }
    }
  }

  @IsTest
  static void internalUserActionsAndDismissesRequests() {
    User partner = partnerUser();
    AI_Insight_Request__c actionable;
    AI_Insight_Request__c dismissable;
    System.runAs(partner) {
      actionable = AIInsightRequestService.submitRequest(
        'LeadFitScoring',
        'Actionable request.'
      );
      dismissable = AIInsightRequestService.submitRequest(
        'LeadFitScoring',
        'Dismissable request.'
      );
    }

    User admin = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSet(admin.Id, 'PartnerSync_AI_Admin');
    System.runAs(admin) {
      Assert.areEqual(2, AIInsightRequestService.getPendingRequests().size());

      AI_Insight_Request__c actioned = AIInsightRequestService.actionRequest(
        actionable.Id
      );
      Assert.areEqual('Actioned', actioned.Status__c);

      AI_Insight_Request__c dismissed = AIInsightRequestService.dismissRequest(
        dismissable.Id
      );
      Assert.areEqual('Dismissed', dismissed.Status__c);

      Assert.areEqual(0, AIInsightRequestService.getPendingRequests().size());

      try {
        AIInsightRequestService.actionRequest(actionable.Id);
        Assert.fail('Expected a not-new rejection on re-action.');
      } catch (PartnerSyncHandledException expected) {
        Assert.isTrue(expected.getMessage().contains('new request'));
      }
    }
  }

  @IsTest
  static void getPendingRequestsRequiresGeneratePermission() {
    User unauthorizedInternal = TestUserFactory.createInternalUser();
    System.runAs(unauthorizedInternal) {
      try {
        AIInsightRequestService.getPendingRequests();
        Assert.fail('Expected a permission failure.');
      } catch (PartnerSyncHandledException expected) {
        Assert.isTrue(expected.getMessage().contains('permission'));
      }
    }
  }
}
