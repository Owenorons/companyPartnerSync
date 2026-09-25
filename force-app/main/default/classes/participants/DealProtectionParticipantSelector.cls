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
}
