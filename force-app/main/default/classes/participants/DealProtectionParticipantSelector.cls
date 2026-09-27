/**
 * Selector layer for Deal_Protection_Participant__c.
 */
public without sharing class DealProtectionParticipantSelector {
  /**
   * Indicates whether an Active shared-protection linkage exists for a
   * participant - feeds DealParticipantCommandService's remove guard.
   *
   * @param dealParticipantId Id of the Deal_Participant__c to check.
   * @return True if an Active Deal_Protection_Participant__c links to it.
   */
  public static Boolean selectActiveForParticipant(Id dealParticipantId) {
    return [
        SELECT COUNT()
        FROM Deal_Protection_Participant__c
        WHERE Deal_Participant__c = :dealParticipantId AND Status__c = 'Active'
        WITH SYSTEM_MODE
      ] > 0;
  }

  /**
   * Locks and reads a single Deal_Protection_Participant__c by Id, for a
   * command to apply an approval decision to.
   *
   * @param protectionParticipantId Id of the record to load.
   * @return The locked Deal_Protection_Participant__c record.
   */
  public static Deal_Protection_Participant__c selectForUpdate(
    Id protectionParticipantId
  ) {
    List<Deal_Protection_Participant__c> rows = [
      SELECT
        Id,
        Protection__c,
        Deal_Participant__c,
        Partner_Account__c,
        Protection_Role__c,
        Status__c,
        Effective_From__c,
        Effective_To__c,
        Share_Percentage__c,
        Contribution_Percentage__c,
        Primary__c
      FROM Deal_Protection_Participant__c
      WHERE Id = :protectionParticipantId
      WITH SYSTEM_MODE
      FOR UPDATE
    ];

    if (rows.isEmpty()) {
      throw new PartnerSyncHandledException(
        'Shared protection request not found.'
      );
    }

    return rows[0];
  }

  /**
   * Queries Proposed (not yet approved) shared-protection requests, for
   * the internal Co-Sell Workbench's "Shared Protection Requests" view.
   *
   * @return Up to 200 Proposed Deal_Protection_Participant__c rows, oldest first.
   */
  public static List<Deal_Protection_Participant__c> selectPendingRequests() {
    return [
      SELECT
        Id,
        Protection__c,
        Protection__r.Deal__c,
        Protection__r.Version_Number__c,
        Partner_Account__c,
        Partner_Account__r.Name,
        Protection_Role__c,
        Share_Percentage__c,
        CreatedDate
      FROM Deal_Protection_Participant__c
      WHERE Status__c = 'Proposed'
      WITH SYSTEM_MODE
      ORDER BY CreatedDate ASC
      LIMIT 200
    ];
  }
}
