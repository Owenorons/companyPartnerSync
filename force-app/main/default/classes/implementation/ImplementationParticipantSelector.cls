/**
 * Selector layer for Implementation_Participant__c.
 */
public without sharing class ImplementationParticipantSelector {
  /**
   * Locks and reads a single implementation participant record by Id.
   *
   * @param implementationParticipantId Id of the record to load.
   * @return The locked Implementation_Participant__c record.
   */
  public static Implementation_Participant__c selectForUpdate(
    Id implementationParticipantId
  ) {
    List<Implementation_Participant__c> rows = [
      SELECT
        Id,
        Implementation__c,
        Deal_Participant__c,
        Deal_Participant__r.Partner_Account__c,
        Role__c,
        Status__c,
        Effective_From__c,
        Effective_To__c,
        Primary__c,
        Responsibility_Summary__c,
        Version_Number__c
      FROM Implementation_Participant__c
      WHERE Id = :implementationParticipantId
      WITH SYSTEM_MODE
      FOR UPDATE
    ];

    if (rows.isEmpty()) {
      throw new PartnerSyncHandledException(
        'Implementation participant not found.'
      );
    }

    return rows[0];
  }

  /**
   * Queries every active participant on an implementation.
   *
   * @param implementationId Id of the implementation.
   * @return The implementation's active participants.
   */
  public static List<Implementation_Participant__c> selectActiveForImplementation(
    Id implementationId
  ) {
    return [
      SELECT
        Id,
        Deal_Participant__c,
        Deal_Participant__r.Partner_Account__c,
        Role__c,
        Primary__c
      FROM Implementation_Participant__c
      WHERE Implementation__c = :implementationId AND Status__c = 'Active'
      WITH SYSTEM_MODE
    ];
  }
}
