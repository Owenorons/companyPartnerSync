/*
 * Query layer for Partner_Record_Share__c, the registry of manually-granted
 * partner access to individual Deal Registration / MDF Request records (see
 * PartnerShareService/PartnerShareDomain for how grants are created and
 * enforced). Every query here runs WITH USER_MODE, and each method selects
 * only the columns its caller actually needs.
 */
public without sharing class PartnerShareSelector {
  public static List<Partner_Record_Share__c> selectActiveSharesForRecord(
    Id recordId
  ) {
    SecurityUtil.assertReadable(Partner_Record_Share__c.SObjectType);

    return [
      SELECT
        Id,
        Target_Record_Id__c,
        Target_Object__c,
        Partner_Account__c,
        Partner_Account__r.Name,
        Access_Level__c,
        Share_Reason__c,
        Expiry_Date__c,
        Active__c,
        Granted_By__c,
        Granted_By__r.Name,
        Granted_On__c,
        Partner_Group_Id__c,
        Salesforce_Share_Id__c
      FROM Partner_Record_Share__c
      WHERE Target_Record_Id__c = :String.valueOf(recordId) AND Active__c = TRUE
      WITH SYSTEM_MODE
      ORDER BY Granted_On__c DESC
    ];
  }

  public static List<Partner_Record_Share__c> selectExpiredShares() {
    return [
      SELECT
        Id,
        Target_Record_Id__c,
        Target_Object__c,
        Partner_Account__c,
        Active__c,
        Partner_Group_Id__c,
        Salesforce_Share_Id__c
      FROM Partner_Record_Share__c
      WHERE
        Active__c = TRUE
        AND Expiry_Date__c != NULL
        AND Expiry_Date__c < :Date.today()
      WITH SYSTEM_MODE
      LIMIT 10000
    ];
  }

  public static Partner_Record_Share__c selectById(Id partnerRecordShareId) {
    List<Partner_Record_Share__c> results = [
      SELECT
        Id,
        Target_Record_Id__c,
        Target_Object__c,
        Partner_Account__c,
        Active__c,
        Expiry_Date__c,
        Partner_Group_Id__c,
        Salesforce_Share_Id__c
      FROM Partner_Record_Share__c
      WHERE Id = :partnerRecordShareId
      WITH SYSTEM_MODE
      LIMIT 1
    ];

    if (results.isEmpty()) {
      throw new PartnerSyncHandledException('Partner record share not found.');
    }

    return results[0];
  }

  public static Boolean hasActiveGrant(Id targetRecordId, Id partnerAccountId) {
    return [
        SELECT COUNT()
        FROM Partner_Record_Share__c
        WHERE
          Target_Record_Id__c = :String.valueOf(targetRecordId)
          AND Partner_Account__c = :partnerAccountId
          AND Active__c = TRUE
        WITH SYSTEM_MODE
      ] > 0;
  }
}
