/**
 * Resolves the subscribing org's commercial license edition
 * (Core/Growth/Enterprise, via TenantConfigService.getEdition()) and checks
 * whether a capability is entitled under that edition, by reading the
 * matching PartnerSync_License_Tier__mdt record. This is the entitlement
 * catalog only: it does not check user permissions, operational feature
 * flags, or usage limits, and nothing calls it yet — wiring it into actual
 * feature gates is a later phase (see license-tier-implementation-plan.md).
 */
public with sharing class PartnerSyncEntitlementService {
  private static PartnerSync_License_Tier__mdt cachedTier;

  /**
   * Returns the org's configured license edition (Core/Growth/Enterprise).
   *
   * @return The tenant's Edition__c value.
   */
  public static String getEdition() {
    return TenantConfigService.getEdition();
  }

  /**
   * Indicates whether the given PartnerSync_License_Tier__mdt checkbox
   * field is entitled under the org's current edition.
   *
   * @param featureApiName The API name of an Enable_*__c field on
   * PartnerSync_License_Tier__mdt (e.g. 'Enable_MDF__c').
   * @return True if the org's edition entitles that capability.
   */
  public static Boolean isFeatureEntitled(String featureApiName) {
    Object value = getTier().get(featureApiName);
    return value == true;
  }

  private static PartnerSync_License_Tier__mdt getTier() {
    if (cachedTier == null) {
      String edition = getEdition();
      cachedTier = String.isBlank(edition)
        ? null
        : PartnerSync_License_Tier__mdt.getInstance(edition);

      if (cachedTier == null) {
        throw new PartnerSyncHandledException(
          'No license tier is configured for edition "' +
            edition +
            '". Please contact your administrator.'
        );
      }
    }

    return cachedTier;
  }

  /**
   * Clears the cached license tier so the next call re-resolves it.
   * Intended for use between test methods.
   */
  public static void clearCacheForTest() {
    cachedTier = null;
  }
}
