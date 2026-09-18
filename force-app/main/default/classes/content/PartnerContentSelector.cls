/**
 * Selector layer for Partner_Content__c and the partner-account context
 * used to evaluate visibility. All queries enforce WITH USER_MODE /
 * readable checks so PartnerContentDomain and PartnerContentService never
 * issue raw SOQL.
 */
public without sharing class PartnerContentSelector {
  /**
   * Returns the partner Account's tier/type fields used to evaluate
   * content visibility.
   *
   * @param partnerAccountId Id of the partner account.
   * @return The Account record with its tier/type fields queried.
   */
  public static Account selectPartnerVisibilityContext(Id partnerAccountId) {
    SecurityUtil.assertReadable(Account.SObjectType);

    List<Account> rows = [
      SELECT Id, Partner_Tier__c, Partner_Type__c
      FROM Account
      WHERE Id = :partnerAccountId AND Is_Partner__c = TRUE
      WITH SYSTEM_MODE
      LIMIT 1
    ];

    if (rows.isEmpty()) {
      throw new PartnerSyncHandledException('Partner account not found.');
    }

    return rows[0];
  }

  /**
   * Returns all active content records, ordered for display.
   *
   * @return Up to 500 active Partner_Content__c records.
   */
  public static List<Partner_Content__c> selectActiveContent() {
    SecurityUtil.assertReadable(Partner_Content__c.SObjectType);

    return [
      SELECT
        Id,
        Name,
        Description__c,
        Category__c,
        Visibility__c,
        Partner_Tier__c,
        Partner_Type__c,
        Content_Document_Id__c,
        Is_Active__c,
        Featured__c,
        Published_Date__c,
        Sort_Order__c
      FROM Partner_Content__c
      WHERE Is_Active__c = TRUE
      WITH SYSTEM_MODE
      ORDER BY Sort_Order__c ASC NULLS LAST, Published_Date__c DESC
      LIMIT 500
    ];
  }

  /**
   * Returns all content records (active and inactive), for the
   * content-management admin UI.
   *
   * @return Up to 500 Partner_Content__c records.
   */
  public static List<Partner_Content__c> selectAllForAdmin() {
    SecurityUtil.assertReadable(Partner_Content__c.SObjectType);

    return [
      SELECT
        Id,
        Name,
        Description__c,
        Category__c,
        Visibility__c,
        Partner_Tier__c,
        Partner_Type__c,
        Is_Active__c,
        Featured__c,
        Sort_Order__c
      FROM Partner_Content__c
      WITH SYSTEM_MODE
      ORDER BY Sort_Order__c ASC NULLS LAST, Name ASC
      LIMIT 500
    ];
  }

  /**
   * Returns a single content record by Id.
   *
   * @param contentId Id of the Partner_Content__c record to fetch.
   * @return The matching Partner_Content__c record.
   */
  public static Partner_Content__c selectById(Id contentId) {
    SecurityUtil.assertReadable(Partner_Content__c.SObjectType);

    List<Partner_Content__c> rows = [
      SELECT
        Id,
        Name,
        Description__c,
        Category__c,
        Visibility__c,
        Partner_Tier__c,
        Partner_Type__c,
        Content_Document_Id__c,
        Is_Active__c,
        Featured__c,
        Published_Date__c,
        Sort_Order__c
      FROM Partner_Content__c
      WHERE Id = :contentId
      WITH SYSTEM_MODE
      LIMIT 1
    ];

    if (rows.isEmpty()) {
      throw new PartnerSyncHandledException('Content not found.');
    }

    return rows[0];
  }
}
