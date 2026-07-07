@IsTest
private class PartnerContentDomainTest {
  @IsTest
  static void allPartnersContentIsVisibleWhenActive() {
    Account partner = PartnerSyncTestDataFactory.partnerAccount('Partner');
    Partner_Content__c content = PartnerSyncTestDataFactory.content(
      'All Partners'
    );

    System.assertEquals(
      true,
      PartnerContentDomain.isVisibleToPartner(content, partner)
    );
  }

  @IsTest
  static void restrictedContentRequiresMatchingPartnerAttributes() {
    Account partner = PartnerSyncTestDataFactory.partnerAccount('Partner');
    Partner_Content__c content = PartnerSyncTestDataFactory.content(
      'Restricted'
    );

    System.assertEquals(
      true,
      PartnerContentDomain.isVisibleToPartner(content, partner)
    );

    partner.Partner_Tier__c = 'Silver';

    System.assertEquals(
      false,
      PartnerContentDomain.isVisibleToPartner(content, partner)
    );
  }

  @IsTest
  static void toDtoMapsContentFields() {
    Partner_Content__c content = PartnerSyncTestDataFactory.content(
      'All Partners'
    );
    insert content;

    PartnerContentDTO dto = PartnerContentDomain.toDTO(content);

    System.assertEquals(content.Id, dto.contentId);
    System.assertEquals('Partner Guide', dto.title);
    System.assertEquals('Sales', dto.category);
    System.assertEquals(true, dto.featured);
  }
}
