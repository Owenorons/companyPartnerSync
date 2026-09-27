/**
 * Selector layer for Deal_Participant_Contribution__c.
 */
public without sharing class DealParticipantContributionSelector {
  /**
   * Reads a single contribution record by Id.
   *
   * @param contributionId Id of the contribution to load.
   * @return The matching Deal_Participant_Contribution__c record.
   */
  public static Deal_Participant_Contribution__c selectById(Id contributionId) {
    List<Deal_Participant_Contribution__c> rows = [
      SELECT
        Id,
        Deal_Participant__c,
        Contribution_Type__c,
        Percentage__c,
        Approved__c
      FROM Deal_Participant_Contribution__c
      WHERE Id = :contributionId
      WITH SYSTEM_MODE
    ];

    if (rows.isEmpty()) {
      throw new PartnerSyncHandledException(
        'Participant contribution not found.'
      );
    }

    return rows[0];
  }
}
