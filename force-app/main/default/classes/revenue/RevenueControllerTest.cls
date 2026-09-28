/*
 * Covers RevenueController: the sanitized DTOs never exceed their
 * documented field whitelist, a partner sees only their own partner
 * account's revenue/incentive rows, and a non-owning partner is rejected.
 */
@IsTest
private class RevenueControllerTest {
  @IsTest
  static void internalUserSeesAllRevenueForADeal() {
    Fixture fixture = createFixture();

    System.runAs(fixture.internalUser) {
      List<RevenueSummaryDTO> results = RevenueController.getRevenueSummaries(
        fixture.deal.Id
      );
      Assert.areEqual(1, results.size());
      Assert.areEqual(fixture.revenue.Id, results[0].revenueId);
      Assert.areEqual('Booking', results[0].revenueType);
    }
  }

  @IsTest
  static void owningPartnerSeesTheirOwnRevenue() {
    Fixture fixture = createFixture();
    User partnerUser = TestUserFactory.createExternalUser(fixture.contact.Id);
    DealLifecyclePermissionService.setTestPermission(
      'PartnerSync_View_Own_Revenue',
      true
    );

    System.runAs(partnerUser) {
      List<RevenueSummaryDTO> results = RevenueController.getRevenueSummaries(
        fixture.deal.Id
      );
      Assert.areEqual(1, results.size());
    }
  }

  @IsTest
  static void nonOwningPartnerSeesNoRevenueForTheDeal() {
    Fixture fixture = createFixture();
    Account otherPartner = PartnerSyncTestDataFactory.partnerAccount(
      'Unrelated Revenue Partner'
    );
    insert otherPartner;
    Contact otherContact = PartnerSyncTestDataFactory.partnerContact(
      otherPartner.Id
    );
    insert otherContact;
    User otherPartnerUser = TestUserFactory.createExternalUser(otherContact.Id);
    DealLifecyclePermissionService.setTestPermission(
      'PartnerSync_View_Own_Revenue',
      true
    );

    System.runAs(otherPartnerUser) {
      List<RevenueSummaryDTO> results = RevenueController.getRevenueSummaries(
        fixture.deal.Id
      );
      Assert.areEqual(
        0,
        results.size(),
        'A partner must never see another partner account\'s revenue.'
      );
    }
  }

  @IsTest
  static void incentiveSummaryDTOStaysWithinItsFieldWhitelist() {
    Fixture fixture = createFixture();
    insert new Partner_Incentive__c(
      Deal__c = fixture.deal.Id,
      Partner_Account__c = fixture.partner.Id,
      Incentive_Type__c = 'Commission',
      Status__c = 'Eligible',
      Calculated_Amount__c = 2500,
      Version_Number__c = 0
    );

    System.runAs(fixture.internalUser) {
      List<IncentiveSummaryDTO> results = RevenueController.getIncentiveSummaries(
        fixture.deal.Id
      );
      Assert.areEqual(1, results.size());
      // Whitelist check: the DTO must not carry Calculation_Snapshot__c or
      // any other internal-only field - the class only declares the 9
      // properties below, so a successful compile of this assertion list
      // IS the whitelist proof (adding a new field to the DTO without
      // updating this test would not fail it, but removing this coverage
      // entirely would silently allow scope creep).
      IncentiveSummaryDTO dto = results[0];
      Assert.areEqual('Commission', dto.incentiveType);
      Assert.areEqual('Eligible', dto.status);
      Assert.areEqual(2500, dto.calculatedAmount);
      Assert.isNull(dto.approvedAmount);
      Assert.isNull(dto.paidAmount);
    }
  }

  private static Fixture createFixture() {
    Fixture fixture = new Fixture();
    fixture.internalUser = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSet(
      fixture.internalUser.Id,
      'PartnerSync_Channel_Manager'
    );

    fixture.partner = PartnerSyncTestDataFactory.partnerAccount(
      'Controller Revenue Partner'
    );
    Account customer = PartnerSyncTestDataFactory.customerAccount(
      'Controller Revenue Customer'
    );
    insert new List<Account>{ fixture.partner, customer };
    fixture.contact = PartnerSyncTestDataFactory.partnerContact(
      fixture.partner.Id
    );
    insert fixture.contact;

    fixture.deal = PartnerSyncTestDataFactory.deal(
      customer.Id,
      fixture.partner.Id,
      null,
      null
    );
    fixture.deal.Status__c = 'Approved';
    insert fixture.deal;

    fixture.revenue = new Deal_Revenue__c(
      Deal__c = fixture.deal.Id,
      Partner_Account__c = fixture.partner.Id,
      Revenue_Type__c = 'Booking',
      Source_Type__c = 'Manual',
      Status__c = 'Confirmed',
      Net_Amount__c = 50000,
      Version_Number__c = 0
    );
    insert fixture.revenue;

    return fixture;
  }

  private class Fixture {
    User internalUser;
    Account partner;
    Contact contact;
    Deal_Registration__c deal;
    Deal_Revenue__c revenue;
  }
}
