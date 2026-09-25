/*
 * Covers PartnerSyncEntitlementService's resolution of the org's license
 * edition into a PartnerSync_License_Tier__mdt entitlement lookup. Relies
 * on the real, deployed Core/Growth/Enterprise catalog records rather than
 * mocking custom metadata (custom metadata cannot be inserted in tests).
 */
@IsTest
private class PartnerSyncEntitlementServiceTest {
  @IsTest
  static void coreEditionDoesNotEntitleMdf() {
    setEdition('Core');

    Assert.isFalse(
      PartnerSyncEntitlementService.isFeatureEntitled('Enable_MDF__c')
    );
  }

  @IsTest
  static void growthEditionEntitlesMdfAndLeadsButNotAi() {
    setEdition('Growth');

    Assert.isTrue(
      PartnerSyncEntitlementService.isFeatureEntitled('Enable_MDF__c')
    );
    Assert.isTrue(
      PartnerSyncEntitlementService.isFeatureEntitled('Enable_Leads__c')
    );
    Assert.isFalse(
      PartnerSyncEntitlementService.isFeatureEntitled('Enable_AI__c')
    );
  }

  @IsTest
  static void enterpriseEditionEntitlesAi() {
    setEdition('Enterprise');

    Assert.isTrue(
      PartnerSyncEntitlementService.isFeatureEntitled('Enable_AI__c')
    );
  }

  @IsTest
  static void unconfiguredEditionFailsCleanly() {
    setEdition('Does Not Exist');

    try {
      PartnerSyncEntitlementService.isFeatureEntitled('Enable_MDF__c');
      Assert.fail('Expected an unconfigured edition to be rejected.');
    } catch (PartnerSyncHandledException expected) {
      Assert.isTrue(
        expected.getMessage().contains('No license tier is configured')
      );
    }
  }

  private static void setEdition(String edition) {
    TenantConfigService.setConfigForTest(
      new Tenant_Config__mdt(Edition__c = edition)
    );
    PartnerSyncEntitlementService.clearCacheForTest();
  }
}
