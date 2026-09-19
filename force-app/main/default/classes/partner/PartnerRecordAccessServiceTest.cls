/*
 * Cross-tenant isolation check for PartnerRecordAccessService: proves an
 * external partner user can't reach another partner's Deal Registration by
 * guessing/passing its Id, even though the deal itself doesn't name them.
 */
@IsTest
private class PartnerRecordAccessServiceTest {
  @IsTest
  static void internalUserBypassesPartnerScopedChecks() {
    PartnerRecordAccessService.assertPartnerAccessToAccount(null);
    PartnerRecordAccessService.assertPartnerAccessToMdf(null);
    PartnerRecordAccessService.assertPartnerAccessToNotification(null);
    PartnerRecordAccessService.assertPartnerAccessToAIInsight(null);
  }

  @IsTest
  static void partnerAccessesOnlyRecordsInItsOwnScope() {
    Account partner = PartnerSyncTestDataFactory.partnerAccount(
      'Scoped Partner'
    );
    insert partner;
    Account otherPartner = PartnerSyncTestDataFactory.partnerAccount(
      'Other Partner'
    );
    insert otherPartner;
    Contact contact = PartnerSyncTestDataFactory.partnerContact(partner.Id);
    insert contact;
    Partner_Content__c content = PartnerSyncTestDataFactory.content(
      'All Partners'
    );
    insert content;
    User partnerUser = TestUserFactory.createExternalUser(contact.Id);
    TestUserFactory.assignPermissionSet(
      partnerUser.Id,
      'PartnerSync_Partner_User'
    );
    TestUserFactory.assignPermissionSet(partnerUser.Id, 'PartnerSync_AI_User');
    System.runAs(partnerUser) {
      MDF_Request__c mdf = PartnerSyncTestDataFactory.mdfRequest(
        partner.Id,
        contact.Id
      );
      insert mdf;
      Partner_Notification__c notification = new Partner_Notification__c(
        Partner_Account__c = partner.Id,
        Recipient_User__c = partnerUser.Id,
        Title__c = 'Scoped notification',
        Message__c = 'Visible only to its recipient',
        Is_Read__c = false,
        Dismissed__c = false
      );
      insert notification;

      PartnerRecordAccessService.assertPartnerAccessToAccount(partner.Id);
      PartnerRecordAccessService.assertPartnerAccessToMdf(mdf.Id);
      PartnerRecordAccessService.assertPartnerAccessToNotification(
        notification.Id
      );
      PartnerRecordAccessService.assertPartnerAccessToContent(content.Id);
      assertBlockedAccount(otherPartner.Id);
    }
  }

  private static void assertBlockedAccount(Id accountId) {
    try {
      PartnerRecordAccessService.assertPartnerAccessToAccount(accountId);
      Assert.fail('Expected cross-partner account rejection.');
    } catch (PartnerSyncHandledException expected) {
      Assert.isTrue(expected.getMessage().contains('not accessible'));
    }
  }

  @IsTest
  static void partnerCannotAccessAnotherPartnerDeal() {
    Account partnerA = new Account(
      Name = 'Partner A',
      Is_Partner__c = true,
      Partner_Status__c = 'Active'
    );
    insert partnerA;

    Account partnerB = new Account(
      Name = 'Partner B',
      Is_Partner__c = true,
      Partner_Status__c = 'Active'
    );
    insert partnerB;

    Contact contactA = new Contact(
      LastName = 'Partner User A',
      AccountId = partnerA.Id,
      Email = 'partnera@example.com',
      Is_Partner_User__c = true
    );
    insert contactA;

    Account customer = new Account(
      Name = 'Customer One',
      Is_Partner__c = false
    );
    insert customer;

    Deal_Registration__c dealB = new Deal_Registration__c(
      Partner_Account__c = partnerB.Id,
      Customer_Account__c = customer.Id,
      Status__c = 'Submitted',
      Conflict_Status__c = 'No Conflict',
      Estimated_Revenue__c = 10000
    );
    insert dealB;

    User partnerUserA = TestUserFactory.createExternalUser(contactA.Id);

    System.runAs(partnerUserA) {
      Boolean blocked = false;

      try {
        PartnerRecordAccessService.assertPartnerAccessToDeal(dealB.Id);
      } catch (PartnerSyncHandledException ex) {
        blocked = true;
      }

      System.assertEquals(
        true,
        blocked,
        'Partner A should not access Partner B deal.'
      );
    }
  }
}
