/**
 * Tenant-wide reservation ledger, using UTC days for every user. No partner
 * CRUD is granted on the counter; only the permission-gated enqueue path uses
 * this system-mode service. Failed/aborted jobs retain their reservation.
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class AIUsageService {
  @TestVisible
  private static Integer testDailyLimit;

  /**
   * Reserves one unit of today's AI usage quota for the running user,
   * asserting generate-insights permission first and rejecting the
   * request if the configured daily limit has been reached.
   *
   * @return The GMT date the reservation was made against.
   */
  public static Date reserve() {
    PartnerPermissionService.assertCanGenerateAIInsights();
    Date day = System.now().dateGMT();
    String key = String.valueOf(day);
    Integer limitValue = getDailyLimit();
    List<AI_Usage_Day__c> rows = [
      SELECT Id, Reserved_Count__c
      FROM AI_Usage_Day__c
      WHERE Day_Key__c = :key
      LIMIT 1
      FOR UPDATE
    ];
    AI_Usage_Day__c counter;
    if (rows.isEmpty()) {
      // The unique day key arbitrates simultaneous first requests. The loser
      // fails closed and may retry; it never starts an unreserved callout.
      Datetime startOfDay = Datetime.newInstanceGMT(
        day,
        Time.newInstance(0, 0, 0, 0)
      );
      Datetime endOfDay = startOfDay.addDays(1);
      Integer legacyUsage = [
        SELECT COUNT()
        FROM AI_Insight__c
        WHERE CreatedDate >= :startOfDay AND CreatedDate < :endOfDay
      ];
      counter = new AI_Usage_Day__c(
        Day_Key__c = key,
        Reserved_Count__c = legacyUsage
      );
      if (limitValue != null && legacyUsage >= limitValue)
        rejectLimit();
      counter.Reserved_Count__c++;
      try {
        insert counter;
      } catch (DmlException ex) {
        if (
          ex.getDmlStatusCode(0) == 'DUPLICATE_VALUE' ||
          ex.getDmlStatusCode(0) == 'UNABLE_TO_LOCK_ROW'
        ) {
          throw new PartnerSyncHandledException(
            'AI quota is busy. Retry the request.'
          );
        }
        throw ex;
      }
    } else {
      counter = rows[0];
      if (limitValue != null && counter.Reserved_Count__c >= limitValue)
        rejectLimit();
      counter.Reserved_Count__c++;
      update counter;
    }
    return day;
  }

  private static void rejectLimit() {
    throw new PartnerSyncHandledException(
      'The daily AI request limit has been reached. Try again tomorrow or contact your administrator.'
    );
  }

  /**
   * Reserves one unit of today's per-use-case AI interaction quota
   * (AI_Usage_Policy__mdt.Daily_Interaction_Limit__c), layered on top of -
   * not a replacement for - the tenant-wide reserve() above. Does not call
   * reserve() itself; AIInteractionService.execute() calls both.
   * Day_Key__c alone is already unique on AI_Usage_Day__c, so this uses a
   * separate AI_Use_Case_Usage_Day__c object keyed by
   * Use_Case_Key__c + '|' + day rather than reusing that object's schema.
   *
   * @param useCaseKey The use case to reserve quota for.
   * @return True if the reservation succeeded; false if the configured limit has been reached.
   */
  public static Boolean reserveForUseCase(String useCaseKey) {
    Integer limitValue = getUseCaseDailyLimit(useCaseKey);
    if (limitValue == null) {
      return true;
    }

    Date day = System.now().dateGMT();
    String compositeKey = useCaseKey + '|' + String.valueOf(day);
    List<AI_Use_Case_Usage_Day__c> rows = [
      SELECT Id, Reserved_Count__c
      FROM AI_Use_Case_Usage_Day__c
      WHERE Use_Case_Day_Key__c = :compositeKey
      LIMIT 1
      FOR UPDATE
    ];

    if (rows.isEmpty()) {
      if (limitValue <= 0) {
        return false;
      }
      AI_Use_Case_Usage_Day__c counter = new AI_Use_Case_Usage_Day__c(
        Use_Case_Day_Key__c = compositeKey,
        Use_Case_Key__c = useCaseKey,
        Day_Key__c = String.valueOf(day),
        Reserved_Count__c = 1
      );
      try {
        insert counter;
      } catch (DmlException ex) {
        if (
          ex.getDmlStatusCode(0) == 'DUPLICATE_VALUE' ||
          ex.getDmlStatusCode(0) == 'UNABLE_TO_LOCK_ROW'
        ) {
          throw new PartnerSyncHandledException(
            'AI quota is busy. Retry the request.'
          );
        }
        throw ex;
      }
      return true;
    }

    AI_Use_Case_Usage_Day__c counter = rows[0];
    if (counter.Reserved_Count__c >= limitValue) {
      return false;
    }
    counter.Reserved_Count__c++;
    update counter;
    return true;
  }

  private static Integer getUseCaseDailyLimit(String useCaseKey) {
    if (
      Test.isRunningTest() && testUseCaseDailyLimits.containsKey(useCaseKey)
    ) {
      return testUseCaseDailyLimits.get(useCaseKey);
    }
    AI_Usage_Policy__mdt policy = AI_Usage_Policy__mdt.getInstance(useCaseKey);
    if (
      policy == null ||
      !policy.Active__c ||
      policy.Daily_Interaction_Limit__c == null
    ) {
      return null;
    }
    return Integer.valueOf(policy.Daily_Interaction_Limit__c);
  }

  @TestVisible
  private static Map<String, Integer> testUseCaseDailyLimits = new Map<String, Integer>();

  /**
   * Resolves the configured daily AI request limit.
   *
   * @return The configured daily limit, or null if unset, inactive, or unparseable (meaning no limit is enforced).
   */
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
    return parseLimit(setting.Value__c);
  }

  /**
   * Parses the raw AI_Daily_Request_Limit metadata value. Zero is a valid,
   * deliberate limit that blocks every request; negative and nonnumeric
   * values are treated as unset (no limit enforced). Exposed directly so
   * tests can cover this parsing without deploying a "0" custom-metadata
   * record, which Apex tests cannot insert.
   *
   * @param rawValue The metadata record's Value__c field.
   * @return The parsed limit, or null if negative or unparseable.
   */
  @TestVisible
  private static Integer parseLimit(String rawValue) {
    try {
      Integer parsed = Integer.valueOf(rawValue);
      return parsed >= 0 ? parsed : null;
    } catch (Exception ignored) {
      return null;
    }
  }
}
