/*
 * Tests AuditService.log(): confirms success/failure entries persist with
 * the right severity/status, actor type is correctly derived for both
 * partner and internal users, and a null request is silently ignored.
 */
@IsTest
private class AuditServiceTest {
  @IsTest
  static void logPersistsSuccessEntryWithActorType() {
    Account partner = PartnerSyncTestDataFactory.partnerAccount('Partner');
    insert partner;

    Contact contact = PartnerSyncTestDataFactory.partnerContact(partner.Id);
    insert contact;

    User partnerUser = TestUserFactory.createExternalUser(contact.Id);

    AuditLogRequestDTO request = AuditFactory.createSuccess(
      'Deal_Registration__c',
      partner.Id,
      'Submit'
    );
    request.partnerAccountId = partner.Id;
    request.partnerContactId = contact.Id;

    System.runAs(partnerUser) {
      Test.startTest();
      AuditService.log(request);
      Test.stopTest();
    }

    Audit_Log__c logged = [
      SELECT
        Object_Name__c,
        Action__c,
        Severity__c,
        Status__c,
        Performed_By_Type__c,
        Partner_Account__c
      FROM Audit_Log__c
      WHERE Partner_Account__c = :partner.Id
      LIMIT 1
    ];

    System.assertEquals('Deal_Registration__c', logged.Object_Name__c);
    System.assertEquals('Submit', logged.Action__c);
    System.assertEquals('Info', logged.Severity__c);
    System.assertEquals('Success', logged.Status__c);
    System.assertEquals(
      'Partner',
      logged.Performed_By_Type__c,
      'A community/external user should be recorded as a Partner actor.'
    );
  }

  @IsTest
  static void logPersistsFailureEntryWithMetadata() {
    User internalUser = TestUserFactory.createInternalUser();

    AuditLogRequestDTO request = AuditFactory.createFailure(
      'MDF_Request__c',
      null,
      'Approve',
      'Budget exceeded.'
    );

    System.runAs(internalUser) {
      AuditService.log(request);
    }

    Audit_Log__c logged = [
      SELECT Severity__c, Status__c, Metadata_JSON__c, Performed_By_Type__c
      FROM Audit_Log__c
      WHERE Object_Name__c = 'MDF_Request__c'
      LIMIT 1
    ];

    System.assertEquals('Error', logged.Severity__c);
    System.assertEquals('Failed', logged.Status__c);
    System.assertEquals(
      'Internal',
      logged.Performed_By_Type__c,
      'A standard-profile user should be recorded as an Internal actor.'
    );
    System.assert(
      logged.Metadata_JSON__c.contains('Budget exceeded.'),
      'Failure metadata should carry the original error message.'
    );
  }

  @IsTest
  static void logSwallowsNullRequestWithoutError() {
    Boolean threw = false;

    try {
      AuditService.log(null);
    } catch (Exception ex) {
      threw = true;
    }

    System.assertEquals(false, threw);
    System.assertEquals(0, [SELECT COUNT() FROM Audit_Log__c]);
  }
}
