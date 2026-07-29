/*
 * Selector layer for the partner dashboard's Account lookup. Only reads
 * the fields the dashboard tile needs; broader partner Account access
 * lives elsewhere (e.g. PartnerAccessService).
 */
public with sharing class PartnerDashboardSelector {
  public static Account selectPartnerAccount(Id partnerAccountId) {
    SecurityUtil.assertReadable(Account.SObjectType);

    List<Account> rows = [
      SELECT Name, Partner_Status__c, Partner_Tier__c
      FROM Account
      WHERE Id = :partnerAccountId AND Is_Partner__c = TRUE
      WITH USER_MODE
      LIMIT 1
    ];

    if (rows.isEmpty()) {
      throw new PartnerSyncHandledException('Partner account not found.');
    }

    return rows[0];
  }
}
