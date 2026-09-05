@IsTest
private class LeadDistributionSelectorTest {
  @IsTest
  static void selectsValidPartnerAndLeadRecords() {
    User userRecord = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSetGroup(
      userRecord.Id,
      'PSG_Internal_Administrator'
    );
    System.runAs(userRecord) {
      Account partner = PartnerSyncTestDataFactory.partnerAccount(
        'Lead Selector Partner'
      );
      insert partner;
      Contact contact = PartnerSyncTestDataFactory.partnerContact(partner.Id);
      insert contact;
      Lead lead = PartnerSyncTestDataFactory.lead(partner.Id, contact.Id);
      insert lead;

      Assert.areEqual(
        partner.Id,
        LeadDistributionSelector.selectActivePartnerAccount(partner.Id).Id
      );
      Assert.areEqual(
        contact.Id,
        LeadDistributionSelector.selectPartnerContact(contact.Id, partner.Id).Id
      );
      Assert.areEqual(
        lead.Id,
        LeadDistributionSelector.selectInternalLead(lead.Id).Id
      );
      Assert.areEqual(
        1,
        LeadDistributionSelector.selectAssignedLeadsByPartner(partner.Id).size()
      );
    }
  }

  @IsTest
  static void rejectsInvalidPartnerContactAndLead() {
    User userRecord = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSetGroup(
      userRecord.Id,
      'PSG_Internal_Administrator'
    );
    System.runAs(userRecord) {
      Account partner = PartnerSyncTestDataFactory.partnerAccount(
        'Valid Partner'
      );
      Account inactive = PartnerSyncTestDataFactory.partnerAccount(
        'Inactive Partner'
      );
      inactive.Partner_Status__c = 'Inactive';
      insert new List<Account>{ partner, inactive };
      Contact contact = PartnerSyncTestDataFactory.partnerContact(partner.Id);
      insert contact;
      assertInvalidPartner(inactive.Id);
      assertInvalidContact(contact.Id, inactive.Id);
      assertMissingLead();
    }
  }

  private static void assertInvalidPartner(Id accountId) {
    try {
      LeadDistributionSelector.selectActivePartnerAccount(accountId);
      Assert.fail('Expected invalid partner rejection.');
    } catch (PartnerSyncHandledException expected) {
      Assert.isTrue(expected.getMessage().contains('not active'));
    }
  }

  private static void assertInvalidContact(Id contactId, Id accountId) {
    try {
      LeadDistributionSelector.selectPartnerContact(contactId, accountId);
      Assert.fail('Expected invalid contact rejection.');
    } catch (PartnerSyncHandledException expected) {
      Assert.isTrue(expected.getMessage().contains('does not belong'));
    }
  }

  private static void assertMissingLead() {
    try {
      LeadDistributionSelector.selectInternalLead(
        Id.valueOf(
          Lead.SObjectType.getDescribe().getKeyPrefix() + '000000000001'
        )
      );
      Assert.fail('Expected missing lead rejection.');
    } catch (PartnerSyncHandledException expected) {
      Assert.isTrue(expected.getMessage().contains('not found'));
    }
  }
}
