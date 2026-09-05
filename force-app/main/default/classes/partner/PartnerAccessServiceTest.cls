@IsTest
private class PartnerAccessServiceTest {
  @IsTest
  static void internalAdministratorCoversInternalCapabilities() {
    User adminUser = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSetGroup(
      adminUser.Id,
      'PSG_Internal_Administrator'
    );
    System.runAs(adminUser) {
      Assert.isTrue(PartnerAccessService.isInternalUser());
      Assert.isFalse(PartnerAccessService.isExternalUser());
      PartnerAccessService.assertInternalUser();
      PartnerAccessService.assertCurrentUserCanAccessPartnerAccount(
        UserInfo.getUserId()
      );
      Assert.isTrue(PartnerAccessService.canViewDeal(null));
      Assert.isTrue(PartnerAccessService.canEditDeal(null));
      Assert.isTrue(PartnerAccessService.canApproveMDF(null));
      Assert.isTrue(PartnerAccessService.canViewAnalytics());
      Assert.isTrue(PartnerAccessService.canAccessContent(null));
      Assert.isTrue(PartnerAccessService.canApproveDeal(null));
      Assert.isFalse(PartnerAccessService.canSubmitMDF());
      Assert.isTrue(PartnerAccessService.canSubmitDeal());
      PartnerAccessService.assertCanSubmitDeal();
      Assert.isTrue(PartnerAccessService.canViewLead(null));
      Assert.isTrue(PartnerAccessService.canAcceptLead(null));
      Assert.isTrue(PartnerAccessService.canConvertLead(null));
      Assert.isFalse(PartnerAccessService.canUseAI());

      try {
        PartnerAccessService.assertCurrentUserCanAccessPartnerAccount(null);
        Assert.fail('Expected missing partner account rejection.');
      } catch (PartnerSyncHandledException expected) {
        Assert.isTrue(expected.getMessage().contains('required'));
      }
      try {
        PartnerAccessService.getCurrentPartnerAccountId();
        Assert.fail('Expected unlinked internal user rejection.');
      } catch (PartnerSyncHandledException expected) {
        Assert.isTrue(expected.getMessage().contains('not linked'));
      }
      try {
        PartnerAccessService.getCurrentPartnerContact();
        Assert.fail('Expected missing contact rejection.');
      } catch (PartnerSyncHandledException expected) {
        Assert.isTrue(expected.getMessage().contains('could not be found'));
      }

      Partner_Content__c content = PartnerSyncTestDataFactory.content(
        'All Partners'
      );
      insert content;
      Assert.isFalse(PartnerAccessService.canDownloadContent(content.Id));
      content.Content_Document_Id__c = '069000000000001AAA';
      update content;
      Assert.isTrue(PartnerAccessService.canDownloadContent(content.Id));
    }
  }

  @IsTest
  static void externalPartnerCapabilitiesAreAccountScoped() {
    User simulator = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSetGroup(
      simulator.Id,
      'PSG_Internal_Administrator'
    );
    System.runAs(simulator) {
      Account partner = PartnerSyncTestDataFactory.partnerAccount(
        'External Partner'
      );
      Account otherPartner = PartnerSyncTestDataFactory.partnerAccount(
        'Other Partner'
      );
      Account customer = PartnerSyncTestDataFactory.customerAccount('Customer');
      insert new List<Account>{ partner, otherPartner, customer };
      Contact contact = PartnerSyncTestDataFactory.partnerContact(partner.Id);
      contact.Can_Submit_Deals__c = true;
      insert contact;
      Opportunity opportunity = PartnerSyncTestDataFactory.opportunity(
        customer.Id,
        partner.Id,
        contact.Id
      );
      insert opportunity;
      Deal_Registration__c deal = PartnerSyncTestDataFactory.deal(
        customer.Id,
        partner.Id,
        contact.Id,
        opportunity.Id
      );
      Lead lead = PartnerSyncTestDataFactory.lead(partner.Id, contact.Id);
      Partner_Content__c content = PartnerSyncTestDataFactory.content(
        'All Partners'
      );
      content.Content_Document_Id__c = '069000000000001AAA';
      insert deal;
      insert lead;
      insert content;

      PartnerAccessService.internalUserOverride = false;
      PartnerAccessService.partnerAccountIdOverride = partner.Id;
      PartnerAccessService.partnerContactOverride = contact;
      try {
        Assert.isFalse(PartnerAccessService.isInternalUser());
        Assert.isTrue(PartnerAccessService.isExternalUser());
        Assert.areEqual(
          partner.Id,
          PartnerAccessService.getCurrentPartnerAccountId()
        );
        Assert.areEqual(
          contact.Id,
          PartnerAccessService.getCurrentPartnerContact().Id
        );
        Assert.isTrue(PartnerAccessService.canSubmitMDF());
        Assert.isTrue(PartnerAccessService.canSubmitDeal());
        PartnerAccessService.assertCanSubmitDeal();
        PartnerAccessService.assertCurrentUserCanAccessPartnerAccount(
          partner.Id
        );
        Assert.isTrue(PartnerAccessService.canViewDeal(deal.Id));
        Assert.isFalse(PartnerAccessService.canViewDeal(null));
        Assert.isTrue(PartnerAccessService.canViewLead(lead.Id));
        Assert.isFalse(PartnerAccessService.canViewLead(null));
        Assert.isTrue(PartnerAccessService.canAcceptLead(lead.Id));
        Assert.isTrue(PartnerAccessService.canConvertLead(lead.Id));
        Assert.isTrue(PartnerAccessService.canViewAnalytics());
        Assert.isTrue(PartnerAccessService.canAccessContent(content.Id));
        Assert.isFalse(PartnerAccessService.canAccessContent(null));
        Assert.isTrue(PartnerAccessService.canDownloadContent(content.Id));

        assertRejectedAccount(otherPartner.Id);
        try {
          PartnerAccessService.assertInternalUser();
          Assert.fail('Expected external-user rejection.');
        } catch (PartnerSyncHandledException expected) {
          Assert.isTrue(expected.getMessage().contains('internal'));
        }
      } finally {
        PartnerAccessService.internalUserOverride = null;
        PartnerAccessService.partnerAccountIdOverride = null;
        PartnerAccessService.partnerContactOverride = null;
      }
    }
  }

  private static void assertRejectedAccount(Id accountId) {
    try {
      PartnerAccessService.assertCurrentUserCanAccessPartnerAccount(accountId);
      Assert.fail('Expected account-scope rejection.');
    } catch (PartnerSyncHandledException expected) {
      Assert.isTrue(expected.getMessage().contains('not accessible'));
    }
  }
}
