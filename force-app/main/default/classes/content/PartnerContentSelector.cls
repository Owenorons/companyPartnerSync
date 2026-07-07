public with sharing class PartnerContentSelector {
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
      ORDER BY Sort_Order__c ASC NULLS LAST, Published_Date__c DESC
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
        Published_Date__c
      FROM Partner_Content__c
      WHERE Id = :contentId
      LIMIT 1
    ];

    if (rows.isEmpty()) {
      throw new PartnerSyncHandledException('Content not found.');
    }

    return rows[0];
  }
}
