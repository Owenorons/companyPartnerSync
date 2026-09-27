/**
 * Query layer for Partner_Record_Share__c, the registry of manually-granted
 * partner access to individual Deal Registration / MDF Request records (see
 * PartnerShareService/PartnerShareDomain for how grants are created and
 * enforced). Every query here runs WITH USER_MODE, and each method selects
 * only the columns its caller actually needs.
 */
public without sharing class PartnerShareSelector {
  /**
   * Retrieves active share grants for a single target record, most
   * recently granted first.
   *
   * @param recordId Id of the target (Deal Registration or MDF Request)
   * record.
   * @return Active Partner_Record_Share__c records for the record.
   */
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

  /**
   * Retrieves active share grants whose expiry date has passed, for the
   * cleanup batch.
   *
   * @return Up to 10,000 expired, still-active Partner_Record_Share__c
   * records.
   */
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

  /**
   * Retrieves a single share grant by Id.
   *
   * @param partnerRecordShareId Id of the Partner_Record_Share__c to
   * retrieve.
   * @return The matching Partner_Record_Share__c record.
   */
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

  /**
   * Bulk counterpart to selectById(): loads many share grants by Id in one
   * query, for callers revoking several at once.
   *
   * @param partnerRecordShareIds Ids of the Partner_Record_Share__c rows to retrieve.
   * @return The matching Partner_Record_Share__c records (may be fewer than requested).
   */
  public static List<Partner_Record_Share__c> selectByIds(
    List<Id> partnerRecordShareIds
  ) {
    return [
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
      WHERE Id IN :partnerRecordShareIds
      WITH SYSTEM_MODE
    ];
  }

  /**
   * Checks whether an active share grant already exists for the given
   * target record and partner account.
   *
   * @param targetRecordId Id of the target record.
   * @param partnerAccountId Id of the partner Account.
   * @return True if an active grant exists for that record/account pair.
   */
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

  /**
   * Bulk counterpart to hasActiveGrant(): one query instead of one per
   * (record, partner) pair, for callers reconciling many grants at once.
   *
   * @param targetRecordIds Ids of the target records to check.
   * @param partnerAccountIds Ids of the partner accounts to check.
   * @return A set of "targetRecordId|partnerAccountId" keys with an active grant.
   */
  public static Set<String> selectActiveGrantKeys(
    Set<Id> targetRecordIds,
    Set<Id> partnerAccountIds
  ) {
    Set<String> targetRecordIdStrings = new Set<String>();
    for (Id recordId : targetRecordIds) {
      targetRecordIdStrings.add(String.valueOf(recordId));
    }

    Set<String> keys = new Set<String>();
    for (Partner_Record_Share__c share : [
      SELECT Target_Record_Id__c, Partner_Account__c
      FROM Partner_Record_Share__c
      WHERE
        Target_Record_Id__c IN :targetRecordIdStrings
        AND Partner_Account__c IN :partnerAccountIds
        AND Active__c = TRUE
      WITH SYSTEM_MODE
    ]) {
      keys.add(share.Target_Record_Id__c + '|' + share.Partner_Account__c);
    }
    return keys;
  }
}
