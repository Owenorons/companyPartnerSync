/**
 * Reads the single 'Default' Tenant_Config__mdt record to gate feature
 * modules (Deals, Leads, MDF, etc.) and expose org-wide tunables like SLA
 * hours. Caches the custom metadata record in a static variable for the
 * transaction, since Tenant_Config__mdt.getInstance() is called from many
 * places per request and metadata records don't change mid-transaction.
 * clearCacheForTest()/setConfigForTest() exist because static state persists
 * across test methods within the same test class run unless reset.
 */
public with sharing class TenantConfigService {
  private static Tenant_Config__mdt cachedConfig;

  private static Tenant_Config__mdt getConfig() {
    if (cachedConfig == null) {
      cachedConfig = Tenant_Config__mdt.getInstance('Default');
    }

    if (cachedConfig == null) {
      throw new PartnerSyncHandledException(
        'Tenant configuration is missing. Please contact your administrator.'
      );
    }

    return cachedConfig;
  }

  /**
   * Returns the tenant's configured edition.
   *
   * @return The Edition__c value from the tenant's default config.
   */
  public static String getEdition() {
    return getConfig().Edition__c;
  }

  /**
   * Indicates whether the onboarding feature module is enabled for the
   * tenant.
   *
   * @return True if onboarding is enabled; false if disabled or unset.
   */
  public static Boolean isOnboardingEnabled() {
    return getBoolean(getConfig().Enable_Onboarding__c);
  }

  /**
   * Indicates whether the deals feature module is enabled for the tenant.
   *
   * @return True if deals is enabled; false if disabled or unset.
   */
  public static Boolean isDealsEnabled() {
    return getBoolean(getConfig().Enable_Deals__c);
  }

  /**
   * Indicates whether the leads feature module is enabled for the tenant.
   *
   * @return True if leads is enabled; false if disabled or unset.
   */
  public static Boolean isLeadsEnabled() {
    return getBoolean(getConfig().Enable_Leads__c);
  }

  /**
   * Indicates whether the MDF feature module is enabled for the tenant.
   *
   * @return True if MDF is enabled; false if disabled or unset.
   */
  public static Boolean isMdfEnabled() {
    return getBoolean(getConfig().Enable_MDF__c);
  }

  /**
   * Returns the tenant's configured industry, used by
   * MDF_Calculation_Rule__mdt to select industry-specific MDF eligibility
   * rules.
   *
   * @return The tenant's industry developer name, or null if unset.
   */
  public static String getIndustry() {
    return getConfig().Industry__r == null
      ? null
      : getConfig().Industry__r.DeveloperName;
  }

  /**
   * Indicates whether the content feature module is enabled for the
   * tenant.
   *
   * @return True if content is enabled; false if disabled or unset.
   */
  public static Boolean isContentEnabled() {
    return getBoolean(getConfig().Enable_Content__c);
  }

  /**
   * Indicates whether outbound webhook dispatch is enabled for the
   * tenant.
   *
   * @return True if webhook dispatch is enabled; false if disabled or unset.
   */
  public static Boolean isWebhooksEnabled() {
    return getBoolean(getConfig().Enable_Webhooks__c);
  }

  /**
   * Indicates whether the analytics feature module is enabled for the
   * tenant.
   *
   * @return True if analytics is enabled; false if disabled or unset.
   */
  public static Boolean isAnalyticsEnabled() {
    return getBoolean(getConfig().Enable_Analytics__c);
  }

  /**
   * Indicates whether the AI feature module is enabled for the tenant.
   *
   * @return True if AI is enabled; false if disabled or unset.
   */
  public static Boolean isAiEnabled() {
    return getBoolean(getConfig().Enable_AI__c);
  }

  /**
   * Returns the number of days after which an open deal registration
   * expires.
   *
   * @return The configured deal expiry days, or 30 if unset.
   */
  public static Integer getDealExpiryDays() {
    Decimal value = getConfig().Deal_Expiry_Days__c;
    return value == null ? 30 : Integer.valueOf(value);
  }

  // Null means unlimited — unlike getDealExpiryDays(), there's no sensible
  // universal default cap, so an unset value must not silently start
  // throttling every tenant that hasn't configured one.
  /**
   * Returns the maximum number of open deal registrations allowed per
   * partner.
   *
   * @return The configured maximum, or null if unset (meaning unlimited).
   */
  public static Integer getMaxOpenDealsPerPartner() {
    Decimal value = getConfig().Max_Open_Deals_Per_Partner__c;
    return value == null ? null : Integer.valueOf(value);
  }

  /**
   * Returns the SLA window, in hours, within which an assigned lead is
   * expected to be actioned.
   *
   * @return The configured lead SLA hours, or 48 if unset.
   */
  public static Integer getLeadSlaHours() {
    Decimal value = getConfig().Lead_SLA_Hours__c;
    return value == null ? 48 : Integer.valueOf(value);
  }

  /**
   * Clears the cached tenant config so the next call re-reads custom
   * metadata. Intended for use between test methods, since static state
   * otherwise persists across them within the same test class run.
   */
  public static void clearCacheForTest() {
    cachedConfig = null;
  }

  /**
   * Overrides the cached tenant config, for use in tests that need specific
   * configuration values without relying on org custom metadata.
   *
   * @param config The Tenant_Config__mdt record to use as the cached config.
   */
  public static void setConfigForTest(Tenant_Config__mdt config) {
    cachedConfig = config;
  }

  private static Boolean getBoolean(Boolean value) {
    return value == null ? false : value;
  }
}
