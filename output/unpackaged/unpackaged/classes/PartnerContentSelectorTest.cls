@IsTest
private class PartnerContentSelectorTest {
  @IsTest
  static void selectsCatalogAndPartnerContext() {
    Account partner = new Account(
      Name = 'Catalog Partner',
      Is_Partner__c = true,
      Partner_Status__c = 'Active',
      Partner_Tier__c = 'Gold',
      Partner_Type__c = 'Reseller'
    );
    insert partner;
    Partner_Content__c active = PartnerSyncTestDataFactory.content(
      'All Partners'
    );
    active.Is_Active__c = true;
    Partner_Content__c inactive = PartnerSyncTestDataFactory.content(
      'Internal Only'
    );
    inactive.Is_Active__c = false;
    insert new List<Partner_Content__c>{ active, inactive };
    Assert.areEqual(
      partner.Id,
      PartnerContentSelector.selectPartnerVisibilityContext(partner.Id).Id
    );
    Assert.areEqual(1, PartnerContentSelector.selectActiveContent().size());
    Assert.areEqual(2, PartnerContentSelector.selectAllForAdmin().size());
    Assert.areEqual(active.Id, PartnerContentSelector.selectById(active.Id).Id);
  }
}
