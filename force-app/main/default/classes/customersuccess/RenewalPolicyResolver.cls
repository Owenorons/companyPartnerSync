/**
 * Resolves the active Renewal_Policy__mdt/Renewal_SLA__mdt for a product
 * family, matching on exact Product_Family__c first and falling back to
 * the org-level (Product_Family__c = null) policy - the same
 * exact-match-with-fallback shape as
 * Deal_Participant_Access_Policy_Resolver/IncentiveCommandService.resolvePolicy().
 */
public without sharing class RenewalPolicyResolver {
  @TestVisible
  private static Renewal_Policy__mdt testPolicyOverride;
  @TestVisible
  private static Renewal_SLA__mdt testSlaOverride;

  /**
   * Resolves the active renewal policy for a product family.
   *
   * @param productFamily The Product_Family__c to match, or null for the org-level policy.
   * @return The best-matching active Renewal_Policy__mdt.
   */
  public static Renewal_Policy__mdt resolvePolicy(String productFamily) {
    if (Test.isRunningTest() && testPolicyOverride != null) {
      return testPolicyOverride;
    }
    if (String.isNotBlank(productFamily)) {
      List<Renewal_Policy__mdt> exactMatches = [
        SELECT
          Policy_Key__c,
          Planning_Window_Days__c,
          Partner_Confirmation_Days__c,
          Create_Opportunity_Days__c,
          Require_Partner_Confirmation__c,
          Require_Renewal_Review__c,
          Require_Renewal_Approval__c,
          Renewal_Protection_Mode__c,
          Partner_Continuity_Policy__c,
          Allow_Auto_Renewal__c
        FROM Renewal_Policy__mdt
        WHERE Active__c = TRUE AND Product_Family__c = :productFamily
        WITH SYSTEM_MODE
        ORDER BY Priority__c DESC NULLS LAST
        LIMIT 1
      ];
      if (!exactMatches.isEmpty()) {
        return exactMatches[0];
      }
    }

    List<Renewal_Policy__mdt> fallback = [
      SELECT
        Policy_Key__c,
        Planning_Window_Days__c,
        Partner_Confirmation_Days__c,
        Create_Opportunity_Days__c,
        Require_Partner_Confirmation__c,
        Require_Renewal_Review__c,
        Require_Renewal_Approval__c,
        Renewal_Protection_Mode__c,
        Partner_Continuity_Policy__c,
        Allow_Auto_Renewal__c
      FROM Renewal_Policy__mdt
      WHERE Active__c = TRUE AND Product_Family__c = NULL
      WITH SYSTEM_MODE
      ORDER BY Priority__c DESC NULLS LAST
      LIMIT 1
    ];
    if (fallback.isEmpty()) {
      throw new PartnerSyncHandledException(
        'No active Renewal Policy is configured.'
      );
    }
    return fallback[0];
  }

  /**
   * Loads every active renewal policy in a single query, keyed by
   * Product_Family__c ('' for the org-level wildcard row) - for bulk
   * callers (RenewalIdentificationBatch) that need to resolve a policy per
   * row across a whole chunk without one SOQL call per row.
   *
   * @return Active policies keyed by Product_Family__c ('' for the wildcard).
   */
  public static Map<String, Renewal_Policy__mdt> resolveAllActiveByProductFamily() {
    Map<String, Renewal_Policy__mdt> byFamily = new Map<String, Renewal_Policy__mdt>();
    for (Renewal_Policy__mdt row : [
      SELECT
        Policy_Key__c,
        Product_Family__c,
        Priority__c,
        Planning_Window_Days__c,
        Partner_Confirmation_Days__c,
        Create_Opportunity_Days__c,
        Require_Partner_Confirmation__c,
        Require_Renewal_Review__c,
        Require_Renewal_Approval__c,
        Renewal_Protection_Mode__c,
        Partner_Continuity_Policy__c,
        Allow_Auto_Renewal__c
      FROM Renewal_Policy__mdt
      WHERE Active__c = TRUE
      WITH SYSTEM_MODE
      ORDER BY Priority__c DESC NULLS LAST
    ]) {
      String key = String.isBlank(row.Product_Family__c)
        ? ''
        : row.Product_Family__c;
      if (!byFamily.containsKey(key)) {
        byFamily.put(key, row);
      }
    }
    return byFamily;
  }

  /**
   * Picks the best-matching policy from a map built by
   * resolveAllActiveByProductFamily(), exact family match first, falling
   * back to the '' wildcard row.
   *
   * @param byFamily The map returned by resolveAllActiveByProductFamily().
   * @param productFamily The entitlement/renewal's product family.
   * @return The best-matching policy, or null if none is configured at all.
   */
  public static Renewal_Policy__mdt pickFromMap(
    Map<String, Renewal_Policy__mdt> byFamily,
    String productFamily
  ) {
    if (
      String.isNotBlank(productFamily) && byFamily.containsKey(productFamily)
    ) {
      return byFamily.get(productFamily);
    }
    return byFamily.get('');
  }

  /**
   * Resolves the active renewal SLA for a product family.
   *
   * @param productFamily The Product_Family__c to match, or null for the org-level SLA.
   * @return The best-matching active Renewal_SLA__mdt.
   */
  public static Renewal_SLA__mdt resolveSla(String productFamily) {
    if (Test.isRunningTest() && testSlaOverride != null) {
      return testSlaOverride;
    }
    if (String.isNotBlank(productFamily)) {
      List<Renewal_SLA__mdt> exactMatches = [
        SELECT
          Renewal_Identified_Days__c,
          Partner_Confirmation_Days__c,
          Qualification_Days__c,
          Opportunity_Active_Days__c,
          Commercial_Proposal_Days__c,
          Escalation_Days__c
        FROM Renewal_SLA__mdt
        WHERE Active__c = TRUE AND Product_Family__c = :productFamily
        WITH SYSTEM_MODE
        LIMIT 1
      ];
      if (!exactMatches.isEmpty()) {
        return exactMatches[0];
      }
    }

    List<Renewal_SLA__mdt> fallback = [
      SELECT
        Renewal_Identified_Days__c,
        Partner_Confirmation_Days__c,
        Qualification_Days__c,
        Opportunity_Active_Days__c,
        Commercial_Proposal_Days__c,
        Escalation_Days__c
      FROM Renewal_SLA__mdt
      WHERE Active__c = TRUE AND Product_Family__c = NULL
      WITH SYSTEM_MODE
      LIMIT 1
    ];
    return fallback.isEmpty() ? new Renewal_SLA__mdt() : fallback[0];
  }
}
