/*
 * Cross-tenant isolation coverage for PartnerAccessService's canX() checks —
 * confirms a partner user can act on their own records but is blocked from
 * another partner's, independent of PartnerRecordAccessService's own tests.
 */
@IsTest
private class PartnerAccessServiceTest {
  @IsTest
  static void canViewDealTrueForOwningPartnerFalseForAnother() {
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
      Email = 'partneraview@example.com',
      Is_Partner_User__c = true
    );
    insert contactA;

    Account customer = new Account(Name = 'Customer', Is_Partner__c = false);
    insert customer;

    Deal_Registration__c dealA = new Deal_Registration__c(
      Partner_Account__c = partnerA.Id,
      Customer_Account__c = customer.Id,
      Status__c = 'Submitted',
      Conflict_Status__c = 'No Conflict',
      Estimated_Revenue__c = 10000
    );
    insert dealA;

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
      System.assertEquals(
        true,
        PartnerAccessService.canViewDeal(dealA.Id),
        'Partner A should be able to view their own deal.'
      );
      System.assertEquals(
        false,
        PartnerAccessService.canViewDeal(dealB.Id),
        'Partner A should not be able to view Partner B deal.'
      );
    }
  }

  @IsTest
  static void canViewDealTrueForInternalUser() {
    Account partner = new Account(
      Name = 'Partner',
      Is_Partner__c = true,
      Partner_Status__c = 'Active'
    );
    insert partner;

    Account customer = new Account(Name = 'Customer', Is_Partner__c = false);
    insert customer;

    Deal_Registration__c deal = new Deal_Registration__c(
      Partner_Account__c = partner.Id,
      Customer_Account__c = customer.Id,
      Status__c = 'Submitted',
      Conflict_Status__c = 'No Conflict',
      Estimated_Revenue__c = 10000
    );
    insert deal;

    User internalUser = TestUserFactory.createInternalUser();

    System.runAs(internalUser) {
      System.assertEquals(
        true,
        PartnerAccessService.canViewDeal(deal.Id),
        'Internal users can view any deal.'
      );
    }
  }

  @IsTest
  static void canEditDealAndCanApproveMdfAreInternalOnly() {
    User internalUser = TestUserFactory.createInternalUser();
    Account partner = new Account(
      Name = 'Partner',
      Is_Partner__c = true,
      Partner_Status__c = 'Active'
    );
    insert partner;

    Contact contact = new Contact(
      LastName = 'Partner User',
      AccountId = partner.Id,
      Email = 'partnereditcheck@example.com',
      Is_Partner_User__c = true
    );
    insert contact;

    User partnerUser = TestUserFactory.createExternalUser(contact.Id);

    TestUserFactory.assignPermissionSet(
      internalUser.Id,
      'PartnerSync_Internal_Admin'
    );

    System.runAs(internalUser) {
      System.assertEquals(true, PartnerAccessService.canEditDeal(null));
      System.assertEquals(true, PartnerAccessService.canApproveMDF(null));
    }

    System.runAs(partnerUser) {
      System.assertEquals(false, PartnerAccessService.canEditDeal(null));
      System.assertEquals(false, PartnerAccessService.canApproveMDF(null));
    }
  }

  @IsTest
  static void canViewAnalyticsAlwaysTrueForExternalUsers() {
    Account partner = new Account(
      Name = 'Partner',
      Is_Partner__c = true,
      Partner_Status__c = 'Active'
    );
    insert partner;

    Contact contact = new Contact(
      LastName = 'Partner User',
      AccountId = partner.Id,
      Email = 'partneranalytics@example.com',
      Is_Partner_User__c = true
    );
    insert contact;

    User partnerUser = TestUserFactory.createExternalUser(contact.Id);

    System.runAs(partnerUser) {
      System.assertEquals(
        true,
        PartnerAccessService.canViewAnalytics(),
        'Partners can always view their own analytics.'
      );
    }
  }

  @IsTest
  static void canAccessContentReflectsVisibility() {
    Partner_Content__c publicContent = PartnerSyncTestDataFactory.content(
      'All Partners'
    );
    insert publicContent;

    Partner_Content__c internalOnlyContent = PartnerSyncTestDataFactory.content(
      'Internal Only'
    );
    insert internalOnlyContent;

    Account partner = new Account(
      Name = 'Partner',
      Is_Partner__c = true,
      Partner_Status__c = 'Active',
      Partner_Tier__c = 'Gold',
      Partner_Type__c = 'Reseller'
    );
    insert partner;

    Contact contact = new Contact(
      LastName = 'Partner User',
      AccountId = partner.Id,
      Email = 'partnercontent@example.com',
      Is_Partner_User__c = true
    );
    insert contact;

    User partnerUser = TestUserFactory.createExternalUser(contact.Id);

    System.runAs(partnerUser) {
      System.assertEquals(
        true,
        PartnerAccessService.canAccessContent(publicContent.Id),
        'Content marked All Partners should be accessible.'
      );
      System.assertEquals(
        false,
        PartnerAccessService.canAccessContent(internalOnlyContent.Id),
        'Content marked Internal Only should not be accessible to partners.'
      );
    }
  }
}
