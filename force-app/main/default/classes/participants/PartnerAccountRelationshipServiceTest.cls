@IsTest
private class PartnerAccountRelationshipServiceTest {
  @IsTest
  static void allowsCoSellIsTrueForAnActiveCoSellPermittingRelationship() {
    Account source = PartnerSyncTestDataFactory.partnerAccount('Source');
    Account target = PartnerSyncTestDataFactory.partnerAccount('Target');
    insert new List<Account>{ source, target };
    insert new Partner_Account_Relationship__c(
      Source_Account__c = source.Id,
      Target_Account__c = target.Id,
      Relationship_Type__c = 'Co-Sell',
      Status__c = 'Active',
      Allows_CoSell__c = true,
      Version_Number__c = 0
    );

    Assert.isTrue(
      PartnerAccountRelationshipService.allowsCoSell(source.Id, target.Id)
    );
    // Direction shouldn't matter for the eligibility check.
    Assert.isTrue(
      PartnerAccountRelationshipService.allowsCoSell(target.Id, source.Id)
    );
  }

  @IsTest
  static void allowsCoSellIsFalseWhenTheRelationshipDoesNotPermitIt() {
    Account source = PartnerSyncTestDataFactory.partnerAccount('Source');
    Account target = PartnerSyncTestDataFactory.partnerAccount('Target');
    insert new List<Account>{ source, target };
    insert new Partner_Account_Relationship__c(
      Source_Account__c = source.Id,
      Target_Account__c = target.Id,
      Relationship_Type__c = 'Referral Partner',
      Status__c = 'Active',
      Allows_CoSell__c = false,
      Version_Number__c = 0
    );

    Assert.isFalse(
      PartnerAccountRelationshipService.allowsCoSell(source.Id, target.Id)
    );
  }

  @IsTest
  static void requireActiveRelationshipThrowsWhenNoneExists() {
    Account source = PartnerSyncTestDataFactory.partnerAccount('Source');
    Account target = PartnerSyncTestDataFactory.partnerAccount('Target');
    insert new List<Account>{ source, target };

    try {
      PartnerAccountRelationshipService.requireActiveRelationship(
        source.Id,
        target.Id
      );
      Assert.fail('Expected a missing relationship to be rejected.');
    } catch (PartnerSyncHandledException expected) {
      Assert.isTrue(
        expected.getMessage().contains('No active partner relationship')
      );
    }
  }

  @IsTest
  static void requireActiveRelationshipThrowsWhenCoSellNotAllowed() {
    Account source = PartnerSyncTestDataFactory.partnerAccount('Source');
    Account target = PartnerSyncTestDataFactory.partnerAccount('Target');
    insert new List<Account>{ source, target };
    insert new Partner_Account_Relationship__c(
      Source_Account__c = source.Id,
      Target_Account__c = target.Id,
      Relationship_Type__c = 'Reseller',
      Status__c = 'Active',
      Allows_CoSell__c = false,
      Version_Number__c = 0
    );

    try {
      PartnerAccountRelationshipService.requireActiveRelationship(
        source.Id,
        target.Id
      );
      Assert.fail('Expected a non-co-sell relationship to be rejected.');
    } catch (PartnerSyncHandledException expected) {
      Assert.isTrue(expected.getMessage().contains('does not permit co-sell'));
    }
  }
}
