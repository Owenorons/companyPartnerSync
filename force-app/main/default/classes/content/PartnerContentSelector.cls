/*
 * Selector layer for Partner_Content__c and the partner-account context
 * used to evaluate visibility. All queries enforce WITH USER_MODE /
 * readable checks so PartnerContentDomain and PartnerContentService never
 * issue raw SOQL.
 */
public without sharing class PartnerContentSelector {
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
