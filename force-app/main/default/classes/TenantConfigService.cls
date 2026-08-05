/*
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

  public static String getEdition() {
    return getConfig().Edition__c;
  }

  public static Boolean isOnboardingEnabled() {
    return getBoolean(getConfig().Enable_Onboarding__c);
  }

  public static Boolean isDealsEnabled() {
    return getBoolean(getConfig().Enable_Deals__c);
  }

  public static Boolean isLeadsEnabled() {
    return getBoolean(getConfig().Enable_Leads__c);
  }

  public static Boolean isMdfEnabled() {
    return getBoolean(getConfig().Enable_MDF__c);
  }

  public static Boolean isContentEnabled() {
    return getBoolean(getConfig().Enable_Content__c);
  }

  public static Boolean isAnalyticsEnabled() {
    return getBoolean(getConfig().Enable_Analytics__c);
  }

  public static Boolean isAiEnabled() {
    return getBoolean(getConfig().Enable_AI__c);
  }

  public static Integer getDealExpiryDays() {
    Decimal value = getConfig().Deal_Expiry_Days__c;
    return value == null ? 30 : Integer.valueOf(value);
  }

  // Null means unlimited — unlike getDealExpiryDays(), there's no sensible
  // universal default cap, so an unset value must not silently start
  // throttling every tenant that hasn't configured one.
  public static Integer getMaxOpenDealsPerPartner() {
    Decimal value = getConfig().Max_Open_Deals_Per_Partner__c;
    return value == null ? null : Integer.valueOf(value);
  }

  public static Integer getLeadSlaHours() {
    Decimal value = getConfig().Lead_SLA_Hours__c;
    return value == null ? 48 : Integer.valueOf(value);
  }

  public static void clearCacheForTest() {
    cachedConfig = null;
  }

  public static void setConfigForTest(Tenant_Config__mdt config) {
    cachedConfig = config;
  }

  private static Boolean getBoolean(Boolean value) {
    return value == null ? false : value;
  }
}
