/*
 * Sprint 45 Phase 4 - consolidated negative-security/cross-partner
 * isolation suite (architecture-design-and-enhancement.md §45.24/§45.63),
 * proving Partner A cannot access Partner B's records through the real,
 * externally-callable Aura entry points a partner actually uses - not raw
 * SOQL, which would bypass sharing entirely.
 *
 * AI context isolation (AI_Recommendation__c/AI_Feedback__c scoped to the
 * submitting partner's own account) is already covered end-to-end by
 * PortfolioIntelligenceControllerTest.partnerCanSubmitFeedbackOnlyForTheirOwnPartnersRecommendation
 * and is not duplicated here.
 */
@IsTest
private class PartnerCrossIsolationSecurityTest {
  @IsTest
  static void partnerBCannotLoadPartnerAsDealDetail() {
    Fixture fixture = createFixture();
    User partnerBUser = TestUserFactory.createExternalUser(
      fixture.partnerBContact.Id
    );
    TestUserFactory.assignPermissionSet(
      partnerBUser.Id,
      'PartnerSync_Partner_User'
    );

    System.runAs(partnerBUser) {
      try {
        DealRegistrationController.getDealDetail(fixture.partnerADeal.Id);
        Assert.fail(
          'Expected Partner B to be denied access to Partner A\'s deal.'
        );
      } catch (AuraHandledException expected) {
        Assert.isTrue(true);
      }
    }
  }

  @IsTest
  static void partnerBsMyDealsListDoesNotIncludePartnerAsDeal() {
    Fixture fixture = createFixture();
    User partnerBUser = TestUserFactory.createExternalUser(
      fixture.partnerBContact.Id
    );
    TestUserFactory.assignPermissionSet(
      partnerBUser.Id,
      'PartnerSync_Partner_User'
    );

    System.runAs(partnerBUser) {
      List<DealRegistrationListDTO> myDeals = DealRegistrationController.getMyDeals();
      for (DealRegistrationListDTO row : myDeals) {
        Assert.areNotEqual(
          fixture.partnerADeal.Id,
          row.dealId,
          'Partner B\'s deal list must never include Partner A\'s deal.'
        );
      }
    }
  }

  @IsTest
  static void partnerBsMyRenewalsListDoesNotIncludePartnerAsRenewal() {
    Fixture fixture = createFixture();
    User partnerBUser = TestUserFactory.createExternalUser(
      fixture.partnerBContact.Id
    );
    TestUserFactory.assignPermissionSet(
      partnerBUser.Id,
      'PartnerSync_Partner_User'
    );

    System.runAs(partnerBUser) {
      List<RenewalSummaryDTO> myRenewals = CustomerSuccessController.getMyRenewals();
      for (RenewalSummaryDTO row : myRenewals) {
        Assert.areNotEqual(
          fixture.partnerARenewal.Id,
          row.renewalId,
          'Partner B\'s renewal list must never include Partner A\'s renewal.'
        );
      }
    }
  }

  @IsTest
  static void externalPartnerUserCannotReachInternalOnlyRevenueDisputes() {
    Fixture fixture = createFixture();
    User partnerBUser = TestUserFactory.createExternalUser(
      fixture.partnerBContact.Id
    );

    System.runAs(partnerBUser) {
      try {
        RevenueController.getOpenDisputes();
        Assert.fail(
          'Expected an external partner user to be rejected from the internal-only revenue dispute queue.'
        );
      } catch (AuraHandledException expected) {
        Assert.isTrue(true);
      }
    }
  }

  private static Fixture createFixture() {
    Fixture fixture = new Fixture();
    Account partnerA = PartnerSyncTestDataFactory.partnerAccount(
      'Isolation Partner A'
    );
    Account partnerB = PartnerSyncTestDataFactory.partnerAccount(
      'Isolation Partner B'
    );
    Account customer = PartnerSyncTestDataFactory.customerAccount(
      'Isolation Customer'
    );
    insert new List<Account>{ partnerA, partnerB, customer };

    Contact partnerAContact = PartnerSyncTestDataFactory.partnerContact(
      partnerA.Id
    );
    insert partnerAContact;
    fixture.partnerBContact = PartnerSyncTestDataFactory.partnerContact(
      partnerB.Id
    );
    insert fixture.partnerBContact;

    fixture.partnerADeal = PartnerSyncTestDataFactory.deal(
      customer.Id,
      partnerA.Id,
      partnerAContact.Id,
      null
    );
    insert fixture.partnerADeal;

    Customer_Success_Engagement__c engagement = new Customer_Success_Engagement__c(
      Customer_Account__c = customer.Id,
      Primary_Partner__c = partnerA.Id,
      Status__c = 'Active',
      Health_Status__c = 'Not Assessed',
      Version_Number__c = 0
    );
    insert engagement;

    fixture.partnerARenewal = new Partner_Renewal__c(
      Customer_Success_Engagement__c = engagement.Id,
      Customer_Account__c = customer.Id,
      Original_Deal__c = fixture.partnerADeal.Id,
      Primary_Partner__c = partnerA.Id,
      Status__c = 'Approved',
      Renewal_Health__c = 'On Track',
      Version_Number__c = 0
    );
    insert fixture.partnerARenewal;

    insert new Partner_Revenue_Dispute__c(
      Partner_Account__c = partnerA.Id,
      Dispute_Type__c = 'Missing Revenue',
      Status__c = 'Open',
      Description__c = 'Isolation test dispute.',
      Submitted_On__c = System.now()
    );

    return fixture;
  }

  private class Fixture {
    Contact partnerBContact;
    Deal_Registration__c partnerADeal;
    Partner_Renewal__c partnerARenewal;
  }
}
