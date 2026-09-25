/**
 * Selector layer for the Partner_Lead_Assignment__c aggregate: eligible
 * partner-candidate discovery for distribution, and lookups used by the
 * accept/reject command flow.
 */
public without sharing class PartnerLeadAssignmentSelector {
  /**
   * Queries every active, non-active-rule-excluded Lead_Distribution_Rule__mdt record, ordered
   * by priority.
   *
   * @return Active distribution rules, lowest Priority__c (highest priority) first.
   */
  public static List<Lead_Distribution_Rule__mdt> selectActiveRules() {
    return [
      SELECT
        DeveloperName,
        Distribution_Method__c,
        Assignment_Method__c,
        Priority__c,
        Country__c,
        Region__c,
        Industry__c,
        Partner_Tier__c,
        Partner_Type__c
      FROM Lead_Distribution_Rule__mdt
      WHERE Active__c = TRUE
      WITH SYSTEM_MODE
      ORDER BY Priority__c NULLS LAST, DeveloperName
    ];
  }

  /**
   * Queries active partner accounts, in Apex-filterable form for rule-criteria matching. Not
   * scoped by rule here - candidate-source volume for a channel program is modest, so filtering
   * happens in Apex (RuleCriteriaService.matches) rather than building dynamic SOQL per rule.
   *
   * @return Up to 2000 active partner accounts.
   */
  public static List<Account> selectActivePartnerAccounts() {
    return [
      SELECT
        Id,
        BillingCountry,
        Partner_Region__c,
        Industry,
        Partner_Tier__c,
        Partner_Type__c
      FROM Account
      WHERE Is_Partner__c = TRUE AND Partner_Status__c = 'Active'
      WITH SYSTEM_MODE
      LIMIT 2000
    ];
  }

  /**
   * Queries the currently active assignment for a lead (Status__c = Assigned), if any.
   *
   * @param leadId Id of the lead to look up.
   * @return The active Partner_Lead_Assignment__c record, or null if none exists.
   */
  public static Partner_Lead_Assignment__c selectActiveForLead(Id leadId) {
    List<Partner_Lead_Assignment__c> rows = [
      SELECT
        Id,
        Lead__c,
        Partner_Account__c,
        Partner_Contact__c,
        Status__c,
        Version_Number__c
      FROM Partner_Lead_Assignment__c
      WHERE Active_Assignment_Key__c = :String.valueOf(leadId)
      WITH SYSTEM_MODE
      LIMIT 1
    ];

    return rows.isEmpty() ? null : rows[0];
  }

  /**
   * Locks and reads a single assignment record by Id, for the command service to apply a
   * decision to.
   *
   * @param assignmentId Id of the assignment to load.
   * @return The locked Partner_Lead_Assignment__c record.
   */
  public static Partner_Lead_Assignment__c selectForUpdate(Id assignmentId) {
    List<Partner_Lead_Assignment__c> rows = [
      SELECT
        Id,
        Lead__c,
        Partner_Account__c,
        Partner_Contact__c,
        Status__c,
        Version_Number__c
      FROM Partner_Lead_Assignment__c
      WHERE Id = :assignmentId
      WITH SYSTEM_MODE
      FOR UPDATE
    ];

    if (rows.isEmpty()) {
      throw new PartnerSyncHandledException('Lead assignment not found.');
    }

    return rows[0];
  }
}
