/*
 * Tests AuditQueryService's permission gate: a Channel Manager (holding the
 * internal-analytics permission) can query audit history for a record, a
 * plain internal user cannot.
 */
@IsTest
private class AuditQueryServiceTest {
  @IsTest
  static void channelManagerCanQueryAuditForRecord() {
    Account partner = PartnerSyncTestDataFactory.partnerAccount('Partner');
    insert partner;

    insert new Audit_Log__c(
      Audit_Timestamp__c = System.now(),
      Object_Name__c = 'Account',
      Record_Id__c = partner.Id,
      Action__c = 'Update',
      Severity__c = 'Info',
      Status__c = 'Success'
    );

    User channelManager = TestUserFactory.createInternalUser();

    TestUserFactory.assignPermissionSet(
      channelManager.Id,
      'PartnerSync_Channel_Manager'
    );

    System.runAs(channelManager) {
      List<Audit_Log__c> results = AuditQueryService.getAuditForRecord(
        partner.Id
      );

      System.assertEquals(1, results.size());
      System.assertEquals('Update', results[0].Action__c);
    }
  }

  @IsTest
  static void plainInternalUserIsBlockedFromAuditQuery() {
    Account partner = PartnerSyncTestDataFactory.partnerAccount('Partner');
    insert partner;

    insert new Audit_Log__c(
      Audit_Timestamp__c = System.now(),
      Object_Name__c = 'Account',
      Record_Id__c = partner.Id,
      Action__c = 'Update',
      Severity__c = 'Info',
      Status__c = 'Success'
    );

    User plainInternalUser = TestUserFactory.createInternalUser();

    System.runAs(plainInternalUser) {
      Boolean threw = false;

      try {
        AuditQueryService.getAuditForRecord(partner.Id);
      } catch (PartnerSyncHandledException ex) {
        threw = true;
      }

      System.assertEquals(
        true,
        threw,
        'A user with no analytics permission set should be blocked from audit queries.'
      );
    }
  }
}
