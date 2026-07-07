/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an org are executed whenever Apex code is deployed
 * to a production org to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production org. In addition, all triggers must have some code coverage.
 *
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the org size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
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
