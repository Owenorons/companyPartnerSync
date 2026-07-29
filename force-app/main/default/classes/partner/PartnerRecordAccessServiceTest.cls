/*
 * Cross-tenant isolation check for PartnerRecordAccessService: proves an
 * external partner user can't reach another partner's Deal Registration by
 * guessing/passing its Id, even though the deal itself doesn't name them.
 */
@IsTest
private class PartnerRecordAccessServiceTest {
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
