/*
 * Covers PartnerShareController's two failure/success shapes: a permitted
 * channel manager can grant and then see the resulting share, while a plain
 * internal user with no deal-review permission set gets an AuraHandledException
 * rather than a raw system error.
 */
@IsTest
private class PartnerShareControllerTest {
  @IsTest
  static void getActiveSharesReturnsGrantsForChannelManager() {
    User manager = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSetGroup(
      manager.Id,
      'PSG_Internal_Administrator'
    );

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
    System.runAs(manager) {
      PartnerShareController.grantAccess(request);

      List<PartnerShareListDTO> results = PartnerShareController.getActiveShares(
        deal.Id
      );

      System.assertEquals(1, results.size());
      System.assertEquals(coSellPartner.Id, results[0].partnerAccountId);
    }
  }

  @IsTest
  static void getActiveSharesBlockedForPlainInternalUserSurfacesHandledError() {
    Account owningPartner = PartnerSyncTestDataFactory.partnerAccount(
      'Owning Partner'
    );
    insert owningPartner;

    Account customer = PartnerSyncTestDataFactory.customerAccount('Customer');
    insert customer;

    Deal_Registration__c deal = PartnerSyncTestDataFactory.deal(
      customer.Id,
      owningPartner.Id,
      null,
      null
    );
    insert deal;

    User plainInternalUser = TestUserFactory.createInternalUser();

    System.runAs(plainInternalUser) {
      Boolean threw = false;

      try {
        PartnerShareController.getActiveShares(deal.Id);
      } catch (AuraHandledException ex) {
        threw = true;
      }

      System.assertEquals(
        true,
        threw,
        'A user with no deal-review permission set should be blocked.'
      );
    }
  }
}
