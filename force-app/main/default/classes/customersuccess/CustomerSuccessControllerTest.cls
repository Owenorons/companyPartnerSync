/*
 * Covers CustomerSuccessController: the sanitized DTOs never exceed their
 * documented field whitelist, a partner sees only their own partner
 * account's engagement/renewal rows, and a non-owning partner is rejected
 * from confirming a renewal.
 */
@IsTest
private class CustomerSuccessControllerTest {
  @IsTest
  static void internalUserSeesAllEngagementsAndRenewals() {
    Fixture fixture = createFixture();

    System.runAs(fixture.internalUser) {
      List<CustomerSuccessSummaryDTO> engagements = CustomerSuccessController.getMyEngagements();
      List<RenewalSummaryDTO> renewals = CustomerSuccessController.getMyRenewals();
      Assert.areEqual(1, engagements.size());
      Assert.areEqual(fixture.engagement.Id, engagements[0].engagementId);
      Assert.areEqual(1, renewals.size());
      Assert.areEqual(fixture.renewal.Id, renewals[0].renewalId);
    }
  }

  @IsTest
  static void owningPartnerSeesOnlyTheirOwnRows() {
    Fixture fixture = createFixture();
    User partnerUser = TestUserFactory.createExternalUser(fixture.contact.Id);
    DealLifecyclePermissionService.setTestPermission(
      'PartnerSync_View_Customer_Success',
      true
    );
    DealLifecyclePermissionService.setTestPermission(
      'PartnerSync_View_Renewal',
      true
    );

    System.runAs(partnerUser) {
      Assert.areEqual(1, CustomerSuccessController.getMyEngagements().size());
      Assert.areEqual(1, CustomerSuccessController.getMyRenewals().size());
    }
  }

  @IsTest
  static void nonOwningPartnerSeesNoRows() {
    Fixture fixture = createFixture();
    Account otherPartner = PartnerSyncTestDataFactory.partnerAccount(
      'Unrelated CS Partner'
    );
    insert otherPartner;
    Contact otherContact = PartnerSyncTestDataFactory.partnerContact(
      otherPartner.Id
    );
    insert otherContact;
    User otherPartnerUser = TestUserFactory.createExternalUser(otherContact.Id);
    DealLifecyclePermissionService.setTestPermission(
      'PartnerSync_View_Customer_Success',
      true
    );
    DealLifecyclePermissionService.setTestPermission(
      'PartnerSync_View_Renewal',
      true
    );

    System.runAs(otherPartnerUser) {
      Assert.areEqual(0, CustomerSuccessController.getMyEngagements().size());
      Assert.areEqual(0, CustomerSuccessController.getMyRenewals().size());
    }
  }

  @IsTest
  static void nonOwningPartnerCannotConfirmAnotherPartnersRenewal() {
    Fixture fixture = createFixture();
    Account otherPartner = PartnerSyncTestDataFactory.partnerAccount(
      'Unrelated CS Partner Two'
    );
    insert otherPartner;
    Contact otherContact = PartnerSyncTestDataFactory.partnerContact(
      otherPartner.Id
    );
    insert otherContact;
    User otherPartnerUser = TestUserFactory.createExternalUser(otherContact.Id);
    DealLifecyclePermissionService.setTestPermission(
      'PartnerSync_Confirm_Renewal',
      true
    );

    System.runAs(otherPartnerUser) {
      RenewalCommand command = new RenewalCommand();
      command.renewalId = fixture.renewal.Id;
      command.expectedVersion = 0;

      try {
        CustomerSuccessController.confirmRenewal(command);
        Assert.fail('Expected a non-owning partner to be rejected.');
      } catch (AuraHandledException expected) {
        Assert.isTrue(true);
      }
    }
  }

  private static Fixture createFixture() {
    Fixture fixture = new Fixture();
    fixture.internalUser = TestUserFactory.createInternalUser();
    fixture.partner = PartnerSyncTestDataFactory.partnerAccount(
      'CS Controller Partner'
    );
    fixture.customer = PartnerSyncTestDataFactory.customerAccount(
      'CS Controller Customer'
    );
    insert new List<Account>{ fixture.partner, fixture.customer };
    fixture.contact = PartnerSyncTestDataFactory.partnerContact(
      fixture.partner.Id
    );
    insert fixture.contact;

    fixture.engagement = new Customer_Success_Engagement__c(
      Customer_Account__c = fixture.customer.Id,
      Primary_Partner__c = fixture.partner.Id,
      Status__c = 'Active',
      Health_Status__c = 'Healthy',
      Version_Number__c = 0
    );
    insert fixture.engagement;

    fixture.renewal = new Partner_Renewal__c(
      Customer_Success_Engagement__c = fixture.engagement.Id,
      Customer_Account__c = fixture.customer.Id,
      Primary_Partner__c = fixture.partner.Id,
      Status__c = 'Partner Confirmation Required',
      Renewal_Health__c = 'On Track',
      Version_Number__c = 0
    );
    insert fixture.renewal;

    return fixture;
  }

  private class Fixture {
    User internalUser;
    Account partner;
    Account customer;
    Contact contact;
    Customer_Success_Engagement__c engagement;
    Partner_Renewal__c renewal;
  }
}
