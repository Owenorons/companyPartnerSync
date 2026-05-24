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

  public static Integer getLeadSlaHours() {
    Decimal value = getConfig().Lead_SLA_Hours__c;
    return value == null ? 48 : Integer.valueOf(value);
  }

  public static void clearCacheForTest() {
    cachedConfig = null;
  }

  private static Boolean getBoolean(Boolean value) {
    return value == null ? false : value;
  }
}
