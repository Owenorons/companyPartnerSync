@IsTest
private class AuditNotificationCoverageTest {
  @IsTest
  static void factoryAndAuditServicePersistSuccessAndFailure() {
    User adminUser = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSet(
      adminUser.Id,
      'PartnerSync_Internal_Admin'
    );
    System.runAs(adminUser) {
      Account partner = PartnerSyncTestDataFactory.partnerAccount('Partner');
      insert partner;
      AuditLogRequestDTO success = AuditFactory.createSuccess(
        'Account',
        partner.Id,
        'Create'
      );
      success.partnerAccountId = partner.Id;
      success.recordName = partner.Name;
      success.oldJson = '{}';
      success.newJson = '{"active":true}';
      AuditService.log(null);
      AuditService.log(success);

      AuditLogRequestDTO failure = AuditFactory.createFailure(
        'Account',
        partner.Id,
        'Update',
        'Rejected by policy'
      );
      AuditService.log(failure);
      List<Audit_Log__c> logs = [
        SELECT Action__c, Severity__c, Status__c, Performed_By_Type__c
        FROM Audit_Log__c
        ORDER BY CreatedDate
      ];
      Assert.areEqual(2, logs.size());
      Assert.areEqual('Info', logs[0].Severity__c);
      Assert.areEqual('Success', logs[0].Status__c);
      Assert.areEqual('Internal', logs[0].Performed_By_Type__c);
      Assert.areEqual('Error', logs[1].Severity__c);
      Assert.areEqual('Failed', logs[1].Status__c);
      Assert.isTrue(failure.metadataJson.contains('Rejected by policy'));
    }
  }

  @IsTest
  static void auditConsumerHandlesMappedIgnoredAndBlankIds() {
    User adminUser = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSet(
      adminUser.Id,
      'PartnerSync_Internal_Admin'
    );
    System.runAs(adminUser) {
      AuditEventConsumerService.logBusinessEvent(
        new PartnerSync_Event__e(Event_Type__c = 'Ignored')
      );
      AuditEventConsumerService.logBusinessEvent(
        new PartnerSync_Event__e(
          Event_Type__c = 'DealSubmitted',
          Object_Name__c = 'Deal_Registration__c',
          Record_Id__c = null,
          Partner_Account_Id__c = null
        )
      );
      Assert.areEqual(
        1,
        [SELECT COUNT() FROM Audit_Log__c WHERE Action__c = 'Submit']
      );
    }
  }

  @IsTest
  static void notificationConsumerValidatesAndCreatesForRecipient() {
    NotificationEventConsumerService.notifyBusinessEvent(
      new PartnerSync_Event__e(Event_Type__c = 'Ignored'),
      null
    );
    try {
      NotificationEventConsumerService.notifyBusinessEvent(
        new PartnerSync_Event__e(Event_Type__c = 'DealApproved'),
        new List<User>()
      );
      Assert.fail('Expected missing-recipient rejection.');
    } catch (PartnerSyncHandledException expected) {
      Assert.isTrue(expected.getMessage().contains('No active partner user'));
    }

    User adminUser = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSet(
      adminUser.Id,
      'PartnerSync_Internal_Admin'
    );
    System.runAs(adminUser) {
      Account partner = PartnerSyncTestDataFactory.partnerAccount('Partner');
      insert partner;
      NotificationEventConsumerService.notifyBusinessEvent(
        new PartnerSync_Event__e(
          Event_Type__c = 'DealApproved',
          Object_Name__c = 'Deal_Registration__c',
          Record_Id__c = String.valueOf(partner.Id),
          Partner_Account_Id__c = String.valueOf(partner.Id)
        ),
        new List<User>{ adminUser }
      );
      Partner_Notification__c notification = [
        SELECT Notification_Type__c, Title__c, Message__c, Recipient_User__c
        FROM Partner_Notification__c
        LIMIT 1
      ];
      Assert.areEqual('Deal', notification.Notification_Type__c);
      Assert.areEqual('Deal Approved', notification.Title__c);
      Assert.areEqual(adminUser.Id, notification.Recipient_User__c);
    }
  }
}
