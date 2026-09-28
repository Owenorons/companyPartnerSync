/**
 * Builds the sanitized context sent to an AI provider for a governed use
 * case, from an AI_Context_Policy__mdt allowlist - never a raw SELECT *,
 * and never a field the policy doesn't explicitly name. Read-only, no AI
 * call. Supports a fixed set of objects via an explicit per-object branch
 * (mirrors PartnerShareService's target-object switch) rather than dynamic
 * SOQL, matching this codebase's established static-SOQL convention;
 * adding a new context-eligible object means adding a new branch here, the
 * same tradeoff PartnerShareService already accepts for target objects.
 */
public without sharing class IntelligenceContextService {
  private static final String REDACTED = '[redacted]';

  /**
   * Builds the sanitized context map for a use case and related record,
   * resolving the record's fields strictly through the matching
   * AI_Context_Policy__mdt row(s) for Related_Object__c.
   *
   * @param useCaseKey The governed use case (matches AI_Context_Policy__mdt.Use_Case_Key__c).
   * @param relatedObject The SObject API name of the related record (matches Allowed_Object__c).
   * @param relatedRecordId Id of the related record to build context from.
   * @return The sanitized context map, safe to JSON-serialize and send to a provider.
   */
  public static Map<String, Object> buildContext(
    String useCaseKey,
    String relatedObject,
    Id relatedRecordId
  ) {
    Map<String, Object> context = new Map<String, Object>();
    if (
      String.isBlank(useCaseKey) ||
      String.isBlank(relatedObject) ||
      relatedRecordId == null
    ) {
      return context;
    }

    List<AI_Context_Policy__mdt> policies = [
      SELECT Allowed_Fields__c, Redact_Fields__c
      FROM AI_Context_Policy__mdt
      WHERE
        Active__c = TRUE
        AND Use_Case_Key__c = :useCaseKey
        AND Allowed_Object__c = :relatedObject
      WITH SYSTEM_MODE
    ];
    if (policies.isEmpty()) {
      // Fail closed: no policy configured for this use case/object means
      // no context is ever sent, not an unbounded fallback.
      return context;
    }
    AI_Context_Policy__mdt policy = policies[0];

    Set<String> allowedFields = splitCsv(policy.Allowed_Fields__c);
    Set<String> redactFields = splitCsv(policy.Redact_Fields__c);
    if (allowedFields.isEmpty()) {
      return context;
    }

    Map<String, Object> record = fetchRecord(relatedObject, relatedRecordId);
    if (record == null) {
      return context;
    }

    for (String fieldName : allowedFields) {
      if (!record.containsKey(fieldName)) {
        continue;
      }
      context.put(
        fieldName,
        redactFields.contains(fieldName) ? REDACTED : record.get(fieldName)
      );
    }
    return context;
  }

  private static Map<String, Object> fetchRecord(
    String relatedObject,
    Id relatedRecordId
  ) {
    if (relatedObject == 'Partner_Portfolio_Snapshot__c') {
      List<Partner_Portfolio_Snapshot__c> rows = [
        SELECT
          Health_Score__c,
          Health_Label__c,
          Open_Deal_Count__c,
          At_Risk_Deal_Count__c,
          Active_Engagement_Count__c,
          At_Risk_Engagement_Count__c,
          Upcoming_Renewal_Count__c,
          Renewal_Value_At_Risk__c,
          Open_Expansion_Count__c,
          Churned_Engagement_Count_Trailing_12mo__c,
          Total_Revenue_Trailing_12mo__c
        FROM Partner_Portfolio_Snapshot__c
        WHERE Id = :relatedRecordId
        WITH SYSTEM_MODE
      ];
      if (rows.isEmpty()) {
        return null;
      }
      Partner_Portfolio_Snapshot__c snapshot = rows[0];
      return new Map<String, Object>{
        'Health_Score__c' => snapshot.Health_Score__c,
        'Health_Label__c' => snapshot.Health_Label__c,
        'Open_Deal_Count__c' => snapshot.Open_Deal_Count__c,
        'At_Risk_Deal_Count__c' => snapshot.At_Risk_Deal_Count__c,
        'Active_Engagement_Count__c' => snapshot.Active_Engagement_Count__c,
        'At_Risk_Engagement_Count__c' => snapshot.At_Risk_Engagement_Count__c,
        'Upcoming_Renewal_Count__c' => snapshot.Upcoming_Renewal_Count__c,
        'Renewal_Value_At_Risk__c' => snapshot.Renewal_Value_At_Risk__c,
        'Open_Expansion_Count__c' => snapshot.Open_Expansion_Count__c,
        'Churned_Engagement_Count_Trailing_12mo__c' => snapshot.Churned_Engagement_Count_Trailing_12mo__c,
        'Total_Revenue_Trailing_12mo__c' => snapshot.Total_Revenue_Trailing_12mo__c
      };
    }
    if (relatedObject == 'Partner_Renewal__c') {
      List<Partner_Renewal__c> rows = [
        SELECT Status__c, Renewal_Health__c, Target_Decision_On__c
        FROM Partner_Renewal__c
        WHERE Id = :relatedRecordId
        WITH SYSTEM_MODE
      ];
      if (rows.isEmpty()) {
        return null;
      }
      Partner_Renewal__c renewal = rows[0];
      return new Map<String, Object>{
        'Status__c' => renewal.Status__c,
        'Renewal_Health__c' => renewal.Renewal_Health__c,
        'Target_Decision_On__c' => renewal.Target_Decision_On__c
      };
    }
    if (relatedObject == 'Executive_Snapshot__c') {
      List<Executive_Snapshot__c> rows = [
        SELECT
          Active_Partner_Count__c,
          Average_Health_Score__c,
          Total_Open_Deal_Count__c,
          Total_At_Risk_Deal_Count__c,
          Total_Active_Engagement_Count__c,
          Total_At_Risk_Engagement_Count__c,
          Total_Upcoming_Renewal_Count__c,
          Total_Renewal_Value_At_Risk__c,
          Total_Open_Expansion_Count__c,
          Total_Churned_Engagement_Count_Trailing_12mo__c,
          Total_Revenue_Trailing_12mo__c,
          Open_AI_Recommendation_Count__c
        FROM Executive_Snapshot__c
        WHERE Id = :relatedRecordId
        WITH SYSTEM_MODE
      ];
      if (rows.isEmpty()) {
        return null;
      }
      Executive_Snapshot__c snapshot = rows[0];
      return new Map<String, Object>{
        'Active_Partner_Count__c' => snapshot.Active_Partner_Count__c,
        'Average_Health_Score__c' => snapshot.Average_Health_Score__c,
        'Total_Open_Deal_Count__c' => snapshot.Total_Open_Deal_Count__c,
        'Total_At_Risk_Deal_Count__c' => snapshot.Total_At_Risk_Deal_Count__c,
        'Total_Active_Engagement_Count__c' => snapshot.Total_Active_Engagement_Count__c,
        'Total_At_Risk_Engagement_Count__c' => snapshot.Total_At_Risk_Engagement_Count__c,
        'Total_Upcoming_Renewal_Count__c' => snapshot.Total_Upcoming_Renewal_Count__c,
        'Total_Renewal_Value_At_Risk__c' => snapshot.Total_Renewal_Value_At_Risk__c,
        'Total_Open_Expansion_Count__c' => snapshot.Total_Open_Expansion_Count__c,
        'Total_Churned_Engagement_Count_Trailing_12mo__c' => snapshot.Total_Churned_Engagement_Count_Trailing_12mo__c,
        'Total_Revenue_Trailing_12mo__c' => snapshot.Total_Revenue_Trailing_12mo__c,
        'Open_AI_Recommendation_Count__c' => snapshot.Open_AI_Recommendation_Count__c
      };
    }
    return null;
  }

  private static Set<String> splitCsv(String csv) {
    Set<String> values = new Set<String>();
    if (String.isBlank(csv)) {
      return values;
    }
    for (String value : csv.split(',')) {
      String trimmed = value.trim();
      if (String.isNotBlank(trimmed)) {
        values.add(trimmed);
      }
    }
    return values;
  }
}
