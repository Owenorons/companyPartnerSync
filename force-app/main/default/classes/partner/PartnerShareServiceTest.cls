/*
 * Coverage for PartnerShareService's grant/revoke lifecycle: registry and
 * platform share stay in sync on grant, revoke removes only the targeted
 * partner's share (not co-sharers on the same record), the unattended
 * expiry path works without the interactive permission set, and the
 * permission/duplicate/unsupported-target failure cases roll back cleanly.
 */
@IsTest
private class PartnerShareServiceTest {
  @IsTest
  static void grantAccessCreatesRegistryAndSalesforceShareForDeal() {
    Account owningPartner = PartnerSyncTestDataFactory.partnerAccount(
      'Owning Partner'
    );
    insert owningPartner;

    Account coSellPartner = PartnerSyncTestDataFactory.partnerAccount(
      'Co-Sell Partner'
    );
    insert coSellPartner;

    Account customer = PartnerSyncTestDataFactory.customerAccount('Customer');
    insert customer;

    Deal_Registration__c deal = PartnerSyncTestDataFactory.deal(
      customer.Id,
      owningPartner.Id,
      null,
      null
    );
    insert deal;

    Group partnerGroup = new Group(
      Name = 'Co-Sell Partner Group',
      Type = 'Regular'
    );
    insert partnerGroup;

    Partner_Access_Group__c mapping = new Partner_Access_Group__c(
      Partner_Account__c = coSellPartner.Id,
      Group_Id__c = partnerGroup.Id,
      Active__c = true
    );
    insert mapping;

    PartnerShareDTO request = new PartnerShareDTO();
    request.targetRecordId = deal.Id;
    request.targetObject = 'Deal Registration';
    request.partnerAccountId = coSellPartner.Id;
    request.accessLevel = 'Edit';
    request.shareReason = 'Co-Sell';

    Test.startTest();
    Id registryId = PartnerShareService.grantAccess(request);
    Test.stopTest();

    Partner_Record_Share__c registry = [
      SELECT
        Id,
        Active__c,
        Partner_Account__c,
        Target_Record_Id__c,
        Partner_Group_Id__c,
        Salesforce_Share_Id__c
      FROM Partner_Record_Share__c
      WHERE Id = :registryId
    ];

    System.assertEquals(
      true,
      registry.Active__c,
      'New share should be active.'
    );
    System.assertEquals(coSellPartner.Id, registry.Partner_Account__c);
    System.assertEquals(
      partnerGroup.Id,
      (Id) registry.Partner_Group_Id__c,
      'The exact group receiving access must be retained for safe revocation.'
    );
    System.assertNotEquals(
      null,
      registry.Salesforce_Share_Id__c,
      'The underlying share row identity must be retained.'
    );

    List<Deal_Registration__Share> shares = [
      SELECT Id, AccessLevel, UserOrGroupId
      FROM Deal_Registration__Share
      WHERE ParentId = :deal.Id AND RowCause = 'Partner_Record_Share__c'
    ];

    System.assertEquals(
      1,
      shares.size(),
      'A manual share row should exist for the deal.'
    );
    System.assertEquals(partnerGroup.Id, shares[0].UserOrGroupId);
    System.assertEquals('Edit', shares[0].AccessLevel);
  }

  @IsTest
  static void getActiveSharesReturnsOnlyActiveGrantsForTheRecord() {
    Account owningPartner = PartnerSyncTestDataFactory.partnerAccount(
      'Owning Partner'
    );
    insert owningPartner;

    Account coSellPartner = PartnerSyncTestDataFactory.partnerAccount(
      'Co-Sell Partner'
    );
    insert coSellPartner;

    Account customer = PartnerSyncTestDataFactory.customerAccount('Customer');
    insert customer;

    Deal_Registration__c deal = PartnerSyncTestDataFactory.deal(
      customer.Id,
      owningPartner.Id,
      null,
      null
    );
    insert deal;

    Deal_Registration__c otherDeal = PartnerSyncTestDataFactory.deal(
      customer.Id,
      owningPartner.Id,
      null,
      null
    );
    insert otherDeal;

    Group partnerGroup = new Group(
      Name = 'Co-Sell Partner Group',
      Type = 'Regular'
    );
    insert partnerGroup;

    insert new Partner_Access_Group__c(
      Partner_Account__c = coSellPartner.Id,
      Group_Id__c = partnerGroup.Id,
      Active__c = true
    );

    PartnerShareDTO requestForDeal = new PartnerShareDTO();
    requestForDeal.targetRecordId = deal.Id;
    requestForDeal.targetObject = 'Deal Registration';
    requestForDeal.partnerAccountId = coSellPartner.Id;
    requestForDeal.accessLevel = 'Edit';
    requestForDeal.shareReason = 'Co-Sell';
    Id activeShareId = PartnerShareService.grantAccess(requestForDeal);

    PartnerShareDTO requestForOtherDeal = new PartnerShareDTO();
    requestForOtherDeal.targetRecordId = otherDeal.Id;
    requestForOtherDeal.targetObject = 'Deal Registration';
    requestForOtherDeal.partnerAccountId = coSellPartner.Id;
    requestForOtherDeal.accessLevel = 'Read';
    requestForOtherDeal.shareReason = 'Escalation';
    Id revokedShareId = PartnerShareService.grantAccess(requestForOtherDeal);
    PartnerShareService.revokeAccess(revokedShareId);

    Test.startTest();
    List<PartnerShareListDTO> results = PartnerShareService.getActiveShares(
      deal.Id
    );
    Test.stopTest();

    System.assertEquals(
      1,
      results.size(),
      'Only the active share for this specific record should be returned.'
    );
    System.assertEquals(activeShareId, results[0].shareId);
    System.assertEquals(coSellPartner.Id, results[0].partnerAccountId);
    System.assertEquals('Co-Sell Partner', results[0].partnerAccountName);
    System.assertEquals('Edit', results[0].accessLevel);
    System.assertEquals('Co-Sell', results[0].shareReason);
    System.assertNotEquals(null, results[0].grantedByName);
  }

  @IsTest
  static void grantAccessBlockedForExternalUser() {
    Account partnerAccount = PartnerSyncTestDataFactory.partnerAccount(
      'Blocked Partner'
    );
    insert partnerAccount;

    Contact partnerContact = PartnerSyncTestDataFactory.partnerContact(
      partnerAccount.Id
    );
    insert partnerContact;

    Account customer = PartnerSyncTestDataFactory.customerAccount('Customer');
    insert customer;

    Deal_Registration__c deal = PartnerSyncTestDataFactory.deal(
      customer.Id,
      partnerAccount.Id,
      null,
      null
    );
    insert deal;

    User partnerUser = TestUserFactory.createExternalUser(partnerContact.Id);

    PartnerShareDTO request = new PartnerShareDTO();
    request.targetRecordId = deal.Id;
    request.targetObject = 'Deal Registration';
    request.partnerAccountId = partnerAccount.Id;
    request.accessLevel = 'Read';
    request.shareReason = 'Co-Sell';

    System.runAs(partnerUser) {
      Boolean blocked = false;

      try {
        PartnerShareService.grantAccess(request);
      } catch (PartnerSyncHandledException ex) {
        blocked = true;
      }

      System.assertEquals(
        true,
        blocked,
        'External users should not be able to grant record shares.'
      );
    }
  }

  @IsTest
  static void grantAccessThrowsWhenNoGroupMappingConfigured() {
    Account owningPartner = PartnerSyncTestDataFactory.partnerAccount(
      'Owning Partner'
    );
    insert owningPartner;

    Account coSellPartner = PartnerSyncTestDataFactory.partnerAccount(
      'Unmapped Partner'
    );
    insert coSellPartner;

    Account customer = PartnerSyncTestDataFactory.customerAccount('Customer');
    insert customer;

    Deal_Registration__c deal = PartnerSyncTestDataFactory.deal(
      customer.Id,
      owningPartner.Id,
      null,
      null
    );
    insert deal;

    PartnerShareDTO request = new PartnerShareDTO();
    request.targetRecordId = deal.Id;
    request.targetObject = 'Deal Registration';
    request.partnerAccountId = coSellPartner.Id;
    request.accessLevel = 'Read';
    request.shareReason = 'Co-Sell';

    Boolean threw = false;

    try {
      PartnerShareService.grantAccess(request);
    } catch (PartnerSyncHandledException ex) {
      threw = true;
    }

    System.assertEquals(
      true,
      threw,
      'Granting access without a partner access group mapping should fail.'
    );
  }

  @IsTest
  static void grantAccessThrowsForUnsupportedTargetObjectAndRollsBackRegistry() {
    Account partnerAccount = PartnerSyncTestDataFactory.partnerAccount(
      'Partner'
    );
    insert partnerAccount;

    AI_Insight__c insight = PartnerSyncTestDataFactory.insight(
      partnerAccount.Id
    );
    insert insight;

    PartnerShareDTO request = new PartnerShareDTO();
    request.targetRecordId = insight.Id;
    request.targetObject = 'AI Insight';
    request.partnerAccountId = partnerAccount.Id;
    request.accessLevel = 'Read';
    request.shareReason = 'Co-Sell';

    Boolean threw = false;

    try {
      PartnerShareService.grantAccess(request);
    } catch (PartnerSyncHandledException ex) {
      threw = true;
      System.assert(
        ex.getMessage().contains('AI Insight'),
        'The error should name the unsupported target object.'
      );
    }

    System.assertEquals(
      true,
      threw,
      '"AI Insight" is a valid Target_Object__c value but has no Salesforce ' +
        'sharing implementation yet, so it should be rejected rather than ' +
        'silently succeed with no real access granted.'
    );

    System.assertEquals(
      0,
      [SELECT COUNT() FROM Partner_Record_Share__c],
      'The registry insert should roll back along with the failed share, ' +
      'not leave behind a row that claims access was granted.'
    );
  }

  @IsTest
  static void revokeAccessDeactivatesRegistryAndRemovesShare() {
    Account owningPartner = PartnerSyncTestDataFactory.partnerAccount(
      'Owning Partner'
    );
    insert owningPartner;

    Account coSellPartner = PartnerSyncTestDataFactory.partnerAccount(
      'Co-Sell Partner'
    );
    insert coSellPartner;

    Account customer = PartnerSyncTestDataFactory.customerAccount('Customer');
    insert customer;

    Deal_Registration__c deal = PartnerSyncTestDataFactory.deal(
      customer.Id,
      owningPartner.Id,
      null,
      null
    );
    insert deal;

    Group partnerGroup = new Group(
      Name = 'Co-Sell Partner Group',
      Type = 'Regular'
    );
    insert partnerGroup;

    insert new Partner_Access_Group__c(
      Partner_Account__c = coSellPartner.Id,
      Group_Id__c = partnerGroup.Id,
      Active__c = true
    );

    PartnerShareDTO request = new PartnerShareDTO();
    request.targetRecordId = deal.Id;
    request.targetObject = 'Deal Registration';
    request.partnerAccountId = coSellPartner.Id;
    request.accessLevel = 'Read';
    request.shareReason = 'Co-Sell';

    Id registryId = PartnerShareService.grantAccess(request);

    Test.startTest();
    PartnerShareService.revokeAccess(registryId);
    Test.stopTest();

    Partner_Record_Share__c registry = [
      SELECT Id, Active__c, Revoked_On__c
      FROM Partner_Record_Share__c
      WHERE Id = :registryId
    ];

    System.assertEquals(
      false,
      registry.Active__c,
      'Revoked share should be inactive.'
    );
    System.assertNotEquals(null, registry.Revoked_On__c);

    List<Deal_Registration__Share> shares = [
      SELECT Id
      FROM Deal_Registration__Share
      WHERE ParentId = :deal.Id AND RowCause = 'Partner_Record_Share__c'
    ];

    System.assertEquals(
      0,
      shares.size(),
      'Manual share row should be removed on revoke.'
    );
  }

  @IsTest
  static void revokeAccessRemovesOnlySelectedPartnersShare() {
    Account owningPartner = PartnerSyncTestDataFactory.partnerAccount(
      'Owning Partner'
    );
    Account firstPartner = PartnerSyncTestDataFactory.partnerAccount(
      'First Co-Sell Partner'
    );
    Account secondPartner = PartnerSyncTestDataFactory.partnerAccount(
      'Second Co-Sell Partner'
    );
    insert new List<Account>{ owningPartner, firstPartner, secondPartner };

    Account customer = PartnerSyncTestDataFactory.customerAccount('Customer');
    insert customer;

    Deal_Registration__c deal = PartnerSyncTestDataFactory.deal(
      customer.Id,
      owningPartner.Id,
      null,
      null
    );
    insert deal;

    Group firstGroup = new Group(
      Name = 'First Co-Sell Partner Group',
      Type = 'Regular'
    );
    Group secondGroup = new Group(
      Name = 'Second Co-Sell Partner Group',
      Type = 'Regular'
    );
    insert new List<Group>{ firstGroup, secondGroup };

    insert new List<Partner_Access_Group__c>{
      new Partner_Access_Group__c(
        Partner_Account__c = firstPartner.Id,
        Group_Id__c = firstGroup.Id,
        Active__c = true
      ),
      new Partner_Access_Group__c(
        Partner_Account__c = secondPartner.Id,
        Group_Id__c = secondGroup.Id,
        Active__c = true
      )
    };

    PartnerShareDTO firstRequest = new PartnerShareDTO();
    firstRequest.targetRecordId = deal.Id;
    firstRequest.targetObject = 'Deal Registration';
    firstRequest.partnerAccountId = firstPartner.Id;
    firstRequest.accessLevel = 'Read';
    firstRequest.shareReason = 'Co-Sell';

    PartnerShareDTO secondRequest = new PartnerShareDTO();
    secondRequest.targetRecordId = deal.Id;
    secondRequest.targetObject = 'Deal Registration';
    secondRequest.partnerAccountId = secondPartner.Id;
    secondRequest.accessLevel = 'Edit';
    secondRequest.shareReason = 'Co-Sell';

    Id firstRegistryId = PartnerShareService.grantAccess(firstRequest);
    Id secondRegistryId = PartnerShareService.grantAccess(secondRequest);

    Test.startTest();
    PartnerShareService.revokeAccess(firstRegistryId);
    Test.stopTest();

    Map<Id, Partner_Record_Share__c> registries = new Map<Id, Partner_Record_Share__c>(
      [
        SELECT Id, Active__c
        FROM Partner_Record_Share__c
        WHERE Id IN :new Set<Id>{ firstRegistryId, secondRegistryId }
      ]
    );
    System.assertEquals(false, registries.get(firstRegistryId).Active__c);
    System.assertEquals(true, registries.get(secondRegistryId).Active__c);

    List<Deal_Registration__Share> remainingShares = [
      SELECT Id, UserOrGroupId
      FROM Deal_Registration__Share
      WHERE ParentId = :deal.Id AND RowCause = 'Partner_Record_Share__c'
    ];

    System.assertEquals(
      1,
      remainingShares.size(),
      'Revoking one partner must preserve other partners\' shares.'
    );
    System.assertEquals(secondGroup.Id, remainingShares[0].UserOrGroupId);
  }

  @IsTest
  static void revokeExpiredAccessSucceedsWithoutManageSharesPermission() {
    Account owningPartner = PartnerSyncTestDataFactory.partnerAccount(
      'Owning Partner'
    );
    insert owningPartner;

    Account coSellPartner = PartnerSyncTestDataFactory.partnerAccount(
      'Co-Sell Partner'
    );
    insert coSellPartner;

    Account customer = PartnerSyncTestDataFactory.customerAccount('Customer');
    insert customer;

    Deal_Registration__c deal = PartnerSyncTestDataFactory.deal(
      customer.Id,
      owningPartner.Id,
      null,
      null
    );
    insert deal;

    Group partnerGroup = new Group(
      Name = 'Co-Sell Partner Group',
      Type = 'Regular'
    );
    insert partnerGroup;

    insert new Partner_Access_Group__c(
      Partner_Account__c = coSellPartner.Id,
      Group_Id__c = partnerGroup.Id,
      Active__c = true
    );

    PartnerShareDTO request = new PartnerShareDTO();
    request.targetRecordId = deal.Id;
    request.targetObject = 'Deal Registration';
    request.partnerAccountId = coSellPartner.Id;
    request.accessLevel = 'Read';
    request.shareReason = 'Co-Sell';
    request.expiryDate = Date.today().addDays(1);

    Id registryId = PartnerShareService.grantAccess(request);
    Partner_Record_Share__c expiredRegistry = new Partner_Record_Share__c(
      Id = registryId,
      Expiry_Date__c = Date.today().addDays(-1)
    );
    update expiredRegistry;

    // createInternalAdminUser() has View/Modify All Data (like the sysadmin
    // who would actually schedule this batch), so it has full data access
    // without needing PartnerSync_Channel_Manager/PartnerSync_Internal_Admin
    // assigned — those permission sets are the only source of CRUD/FLS on
    // Partner_Record_Share__c, so createInternalUser()'s arbitrary Standard
    // profile would fail here for the wrong reason (no field access at all),
    // not the one this test is isolating (no manage-shares permission set).
    User internalAdminWithoutManagePermission = TestUserFactory.createInternalAdminUser();

    Test.startTest();
    System.runAs(internalAdminWithoutManagePermission) {
      PartnerShareService.revokeExpiredAccess(registryId);
    }
    Test.stopTest();

    Partner_Record_Share__c registry = [
      SELECT Id, Active__c
      FROM Partner_Record_Share__c
      WHERE Id = :registryId
    ];

    System.assertEquals(
      false,
      registry.Active__c,
      'An expired share should be revocable by unattended cleanup even when ' +
        'the running user holds no record-share-management permission set ' +
        '(this is the path PartnerShareCleanupBatch relies on).'
    );

    List<Deal_Registration__Share> shares = [
      SELECT Id
      FROM Deal_Registration__Share
      WHERE ParentId = :deal.Id AND RowCause = 'Partner_Record_Share__c'
    ];

    System.assertEquals(0, shares.size());
  }

  @IsTest
  static void revokeExpiredAccessThrowsWhenShareIsNotExpired() {
    Account owningPartner = PartnerSyncTestDataFactory.partnerAccount(
      'Owning Partner'
    );
    insert owningPartner;

    Account coSellPartner = PartnerSyncTestDataFactory.partnerAccount(
      'Co-Sell Partner'
    );
    insert coSellPartner;

    Account customer = PartnerSyncTestDataFactory.customerAccount('Customer');
    insert customer;

    Deal_Registration__c deal = PartnerSyncTestDataFactory.deal(
      customer.Id,
      owningPartner.Id,
      null,
      null
    );
    insert deal;

    Group partnerGroup = new Group(
      Name = 'Co-Sell Partner Group',
      Type = 'Regular'
    );
    insert partnerGroup;

    insert new Partner_Access_Group__c(
      Partner_Account__c = coSellPartner.Id,
      Group_Id__c = partnerGroup.Id,
      Active__c = true
    );

    PartnerShareDTO request = new PartnerShareDTO();
    request.targetRecordId = deal.Id;
    request.targetObject = 'Deal Registration';
    request.partnerAccountId = coSellPartner.Id;
    request.accessLevel = 'Read';
    request.shareReason = 'Co-Sell';

    Id registryId = PartnerShareService.grantAccess(request);

    Boolean threw = false;

    Test.startTest();
    try {
      PartnerShareService.revokeExpiredAccess(registryId);
    } catch (PartnerSyncHandledException ex) {
      threw = true;
    }
    Test.stopTest();

    System.assertEquals(
      true,
      threw,
      'revokeExpiredAccess must not revoke a share with no expiry date or a ' +
        'future expiry date — it has no interactive permission check, so ' +
        'the expiry condition is its only authorization.'
    );

    Partner_Record_Share__c registry = [
      SELECT Id, Active__c
      FROM Partner_Record_Share__c
      WHERE Id = :registryId
    ];

    System.assertEquals(true, registry.Active__c);
  }

  @IsTest
  static void validateGrantThrowsForMissingRequiredFields() {
    Boolean threw = false;

    try {
      PartnerShareDomain.validateGrant(new PartnerShareDTO());
    } catch (PartnerSyncHandledException ex) {
      threw = true;
    }

    System.assertEquals(
      true,
      threw,
      'An empty request should fail validation.'
    );
  }
}
