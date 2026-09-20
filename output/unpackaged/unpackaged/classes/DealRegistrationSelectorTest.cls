@IsTest
private class DealRegistrationSelectorTest {
  @IsTest
  static void selectsRegistrationDataAndConflicts() {
    User userRecord = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSetGroup(
      userRecord.Id,
      'PSG_Internal_Administrator'
    );
    System.runAs(userRecord) {
      Account partner = PartnerSyncTestDataFactory.partnerAccount(
        'Selector Partner'
      );
      Account customer = PartnerSyncTestDataFactory.customerAccount(
        'Selector Customer'
      );
      insert new List<Account>{ partner, customer };
      Contact contact = PartnerSyncTestDataFactory.partnerContact(partner.Id);
      insert contact;
      Opportunity firstOpportunity = PartnerSyncTestDataFactory.opportunity(
        customer.Id,
        partner.Id,
        contact.Id
      );
      firstOpportunity.Name = 'Registered Opportunity';
      Opportunity secondOpportunity = PartnerSyncTestDataFactory.opportunity(
        customer.Id,
        partner.Id,
        contact.Id
      );
      secondOpportunity.Name = 'Eligible Opportunity';
      insert new List<Opportunity>{ firstOpportunity, secondOpportunity };
      Deal_Registration__c firstDeal = PartnerSyncTestDataFactory.deal(
        customer.Id,
        partner.Id,
        contact.Id,
        firstOpportunity.Id
      );
      Deal_Registration__c conflict = PartnerSyncTestDataFactory.deal(
        customer.Id,
        partner.Id,
        contact.Id,
        secondOpportunity.Id
      );
      insert new List<Deal_Registration__c>{ firstDeal, conflict };

      Assert.areEqual(
        firstOpportunity.Id,
        DealRegistrationSelector.selectOpportunityForRegistration(
            firstOpportunity.Id
          )
          .Id
      );
      Assert.isTrue(
        DealRegistrationSelector.hasExistingRegistration(firstOpportunity.Id)
      );
      Assert.isFalse(
        DealRegistrationSelector.hasExistingRegistration(
          fakeId(Opportunity.SObjectType)
        )
      );
      Assert.areEqual(
        0,
        DealRegistrationSelector.selectEligibleOpportunitiesForPartner(
            partner.Id
          )
          .size()
      );
      Assert.areEqual(
        2,
        DealRegistrationSelector.selectPartnerDeals(partner.Id).size()
      );
      Assert.areEqual(
        2,
        DealRegistrationSelector.countOpenDealsForPartner(partner.Id)
      );
      Assert.areEqual(
        firstDeal.Id,
        DealRegistrationSelector.selectById(firstDeal.Id).Id
      );
      Assert.areEqual(
        1,
        DealRegistrationSelector.findConflictingDeals(customer.Id, firstDeal.Id)
          .size()
      );
    }
  }

  @IsTest
  static void rejectsMissingRecords() {
    User userRecord = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSetGroup(
      userRecord.Id,
      'PSG_Internal_Administrator'
    );
    System.runAs(userRecord) {
      assertMissingOpportunity();
      try {
        DealRegistrationSelector.selectById(
          fakeId(Deal_Registration__c.SObjectType)
        );
        Assert.fail('Expected missing deal rejection.');
      } catch (PartnerSyncHandledException expected) {
        Assert.isTrue(expected.getMessage().contains('not found'));
      }
    }
  }

  private static void assertMissingOpportunity() {
    try {
      DealRegistrationSelector.selectOpportunityForRegistration(
        fakeId(Opportunity.SObjectType)
      );
      Assert.fail('Expected missing opportunity rejection.');
    } catch (PartnerSyncHandledException expected) {
      Assert.isTrue(expected.getMessage().contains('not found'));
    }
  }

  private static Id fakeId(Schema.SObjectType objectType) {
    return Id.valueOf(objectType.getDescribe().getKeyPrefix() + '000000000001');
  }
}
