/*
 * Unit tests for PartnerContentDomain's visibility rules and DTO mapping,
 * covering the "All Partners" and "Restricted" (tier/type-matched)
 * visibility branches.
 */
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

  @IsTest
  static void coversVisibilityAdminMappingValidationAndUpdate() {
    Account partner = PartnerSyncTestDataFactory.partnerAccount('Partner');
    Partner_Content__c content = PartnerSyncTestDataFactory.content(
      'All Partners'
    );
    Assert.isFalse(PartnerContentDomain.isVisibleToPartner(null, partner));
    Assert.isFalse(PartnerContentDomain.isVisibleToPartner(content, null));
    content.Is_Active__c = false;
    Assert.isFalse(PartnerContentDomain.isVisibleToPartner(content, partner));
    content.Is_Active__c = true;
    content.Visibility__c = 'Internal Only';
    Assert.isFalse(PartnerContentDomain.isVisibleToPartner(content, partner));
    content.Visibility__c = 'Unknown';
    Assert.isFalse(PartnerContentDomain.isVisibleToPartner(content, partner));
    content.Visibility__c = 'Restricted';
    content.Partner_Tier__c = null;
    content.Partner_Type__c = null;
    Assert.isTrue(PartnerContentDomain.isVisibleToPartner(content, partner));
    content.Partner_Type__c = 'Distributor';
    Assert.isFalse(PartnerContentDomain.isVisibleToPartner(content, partner));

    insert content;
    PartnerContentAdminDTO admin = PartnerContentDomain.toAdminDTO(content);
    Assert.areEqual(content.Id, admin.contentId);
    Assert.areEqual(content.Name, admin.title);
    Assert.areEqual('Restricted', admin.visibility);

    assertInvalidAdmin(null);
    assertInvalidAdmin(new PartnerContentAdminDTO());
    admin.title = null;
    assertInvalidAdmin(admin);
    admin.title = 'Updated Guide';
    admin.description = 'Updated';
    admin.category = 'Marketing';
    admin.featured = true;
    admin.isActive = true;
    admin.visibility = 'All Partners';
    admin.partnerTier = 'Gold';
    admin.partnerType = 'Reseller';
    admin.sortOrder = 10;
    PartnerContentDomain.validateAdminSave(admin);
    Partner_Content__c updated = PartnerContentDomain.applyAdminUpdate(
      content,
      admin
    );
    Assert.areEqual('Updated Guide', updated.Name);
    Assert.areEqual('Updated', updated.Description__c);
    Assert.isTrue(updated.Featured__c);
    Assert.isTrue(updated.Is_Active__c);
    Assert.areEqual(10, updated.Sort_Order__c);
  }

  private static void assertInvalidAdmin(PartnerContentAdminDTO dto) {
    try {
      PartnerContentDomain.validateAdminSave(dto);
      Assert.fail('Expected invalid admin content rejection.');
    } catch (PartnerSyncHandledException expected) {
      Assert.isNotNull(expected);
    }
  }
}
