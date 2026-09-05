/* Enforces the tenant's configured daily AI request cap. Every generation
 * attempt persists an AI_Insight__c record, so that durable ledger is also
 * the source of truth for request counting without introducing a second
 * counter that could drift from actual activity. */
public with sharing class AIUsageService {
  @TestVisible
  private static Integer testDailyLimit;

  public static void assertWithinDailyLimit() {
    Integer limitValue = getDailyLimit();
    if (limitValue == null) {
      return;
    }
    Integer used = [
      SELECT COUNT()
      FROM AI_Insight__c
      WHERE CreatedDate = TODAY
      WITH SYSTEM_MODE
    ];
    if (used >= limitValue) {
      throw new PartnerSyncHandledException(
        'The daily AI request limit has been reached. Try again tomorrow or contact your administrator.'
      );
    }
  }

  public static Integer getDailyLimit() {
    if (Test.isRunningTest() && testDailyLimit != null) {
      return testDailyLimit;
    }
    Tenant_Config__mdt setting = Tenant_Config__mdt.getInstance(
      'AI_Daily_Request_Limit'
    );
    if (
      setting == null ||
      !setting.Active__c ||
      String.isBlank(setting.Value__c)
    ) {
      return null;
    }
    try {
      Integer parsed = Integer.valueOf(setting.Value__c);
      return parsed > 0 ? parsed : null;
    } catch (Exception ignored) {
      return null;
    }
  }
}
