@IsTest
private class PartnerShareServiceTest {
  @IsTest
  static void grantsListsAndRevokesDealAndMdfShares() {
    User manager = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSetGroup(
      manager.Id,
      'PSG_Internal_Administrator'
    );
    Group partnerGroup = new Group(
      Name = 'Partner Share Test Group',
      DeveloperName = 'Partner_Share_Test_Group',
      Type = 'Regular'
    );
    insert partnerGroup;

    System.runAs(manager) {
      SharingFixture fixture = createFixture(partnerGroup.Id);
      PartnerShareDTO dealRequest = request(
        fixture.deal.Id,
        'Deal Registration',
        fixture.partner.Id,
        'Edit'
      );
      Id dealRegistryId = PartnerShareService.grantAccess(dealRequest);
      Assert.isTrue(
        PartnerShareSelector.hasActiveGrant(fixture.deal.Id, fixture.partner.Id)
      );
      Assert.areEqual(
        1,
        PartnerShareSelector.selectActiveSharesForRecord(fixture.deal.Id).size()
      );
      Assert.areEqual(
        1,
        PartnerShareService.getActiveShares(fixture.deal.Id).size()
      );
      Assert.areEqual(
        dealRegistryId,
        PartnerShareSelector.selectById(dealRegistryId).Id
      );

      try {
        PartnerShareService.grantAccess(dealRequest);
        Assert.fail('Expected duplicate grant rejection.');
      } catch (PartnerSyncHandledException expected) {
        Assert.isTrue(expected.getMessage().contains('already has'));
      }
      PartnerShareService.revokeAccess(dealRegistryId);
      Assert.isFalse(
        [
          SELECT Active__c
          FROM Partner_Record_Share__c
          WHERE Id = :dealRegistryId
        ]
        .Active__c
      );

      PartnerShareDTO mdfRequest = request(
        fixture.mdf.Id,
        'MDF Request',
        fixture.partner.Id,
        'Read'
      );
      Id mdfRegistryId = PartnerShareService.grantAccess(mdfRequest);
      try {
        PartnerShareService.revokeExpiredAccess(mdfRegistryId);
        Assert.fail('Expected non-expired rejection.');
      } catch (PartnerSyncHandledException expected) {
        Assert.isTrue(expected.getMessage().contains('not expired'));
      }
      Partner_Record_Share__c expired = [
        SELECT Expiry_Date__c
        FROM Partner_Record_Share__c
        WHERE Id = :mdfRegistryId
      ];
      expired.Expiry_Date__c = Date.today().addDays(-1);
      update expired;
      Assert.areEqual(1, PartnerShareSelector.selectExpiredShares().size());
      PartnerShareService.revokeExpiredAccess(mdfRegistryId);
      Assert.isFalse(
        PartnerShareSelector.hasActiveGrant(fixture.mdf.Id, fixture.partner.Id)
      );
    }
  }

  @IsTest
  static void rejectsMissingRegistryAndGroupMapping() {
    User manager = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSetGroup(
      manager.Id,
      'PSG_Internal_Administrator'
    );
    System.runAs(manager) {
      Account partner = PartnerSyncTestDataFactory.partnerAccount(
        'Unmapped Partner'
      );
      insert partner;
      MDF_Request__c mdf = new MDF_Request__c(
        Partner_Account__c = partner.Id,
        Campaign_Name__c = 'Unmapped',
        Campaign_Type__c = 'Webinar',
        Requested_Amount__c = 100,
        Activity_Start_Date__c = Date.today(),
        Activity_End_Date__c = Date.today().addDays(1),
        Status__c = 'Submitted'
      );
      insert mdf;
      try {
        PartnerShareService.grantAccess(
          request(mdf.Id, 'MDF Request', partner.Id, 'Read')
        );
        Assert.fail('Expected missing mapping rejection.');
      } catch (PartnerSyncHandledException expected) {
        Assert.isTrue(
          expected.getMessage().contains('No partner access group')
        );
      }
      try {
        PartnerShareSelector.selectById(
          fakeId(Partner_Record_Share__c.SObjectType)
        );
        Assert.fail('Expected missing registry rejection.');
      } catch (PartnerSyncHandledException expected) {
        Assert.isTrue(expected.getMessage().contains('not found'));
      }
    }
  }

  private static SharingFixture createFixture(Id groupId) {
    SharingFixture fixture = new SharingFixture();
    fixture.partner = PartnerSyncTestDataFactory.partnerAccount(
      'Shared Partner'
    );
    Account customer = PartnerSyncTestDataFactory.customerAccount(
      'Shared Customer'
    );
    insert new List<Account>{ fixture.partner, customer };
    insert new Partner_Access_Group__c(
      Partner_Account__c = fixture.partner.Id,
      Group_Id__c = String.valueOf(groupId),
      Active__c = true
    );
    Contact contact = PartnerSyncTestDataFactory.partnerContact(
      fixture.partner.Id
    );
    insert contact;
    Opportunity opportunity = PartnerSyncTestDataFactory.opportunity(
      customer.Id,
      fixture.partner.Id,
      contact.Id
    );
    insert opportunity;
    fixture.deal = PartnerSyncTestDataFactory.deal(
      customer.Id,
      fixture.partner.Id,
      contact.Id,
      opportunity.Id
    );
    fixture.mdf = PartnerSyncTestDataFactory.mdfRequest(
      fixture.partner.Id,
      contact.Id
    );
    insert fixture.deal;
    insert fixture.mdf;
    return fixture;
  }

  private static PartnerShareDTO request(
    Id recordId,
    String objectName,
    Id partnerId,
    String accessLevel
  ) {
    PartnerShareDTO request = new PartnerShareDTO();
    request.targetRecordId = recordId;
    request.targetObject = objectName;
    request.partnerAccountId = partnerId;
    request.accessLevel = accessLevel;
    request.shareReason = 'Co-Sell';
    request.expiryDate = Date.today().addDays(30);
    return request;
  }

  private static Id fakeId(Schema.SObjectType objectType) {
    return Id.valueOf(objectType.getDescribe().getKeyPrefix() + '000000000001');
  }

  private class SharingFixture {
    Account partner;
    Deal_Registration__c deal;
    MDF_Request__c mdf;
  }
}
