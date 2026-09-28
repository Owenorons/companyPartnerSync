/**
 * Generates an optional, explicit, internally-triggered AI narrative
 * summarizing an Executive_Snapshot__c's own already-computed numbers -
 * never raw partner records, mirroring
 * PortfolioNarrativeService.generateNarrative() exactly (Sprint 43's
 * "bounded narrative, not raw-record analysis" invariant, enforced
 * structurally by the ExecutiveNarrative use case's
 * AI_Context_Policy__mdt). Never runs automatically as part of
 * ExecutiveSnapshotBatch.
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class ExecutiveNarrativeService {
  /**
   * Generates and persists a narrative for the executive snapshot.
   *
   * @param snapshotId Id of the Executive_Snapshot__c to summarize.
   * @return The updated snapshot.
   */
  public static Executive_Snapshot__c generateNarrative(Id snapshotId) {
    PartnerAccessService.assertInternalUser();
    if (snapshotId == null) {
      throw new PartnerSyncHandledException(
        'An executive snapshot is required.'
      );
    }
    List<Executive_Snapshot__c> rows = [
      SELECT Narrative__c, Narrative_Generated_On__c
      FROM Executive_Snapshot__c
      WHERE Id = :snapshotId
      WITH SYSTEM_MODE
    ];
    if (rows.isEmpty()) {
      throw new PartnerSyncHandledException('Executive snapshot not found.');
    }
    Executive_Snapshot__c snapshot = rows[0];

    AIInteractionService.InteractionResult result = AIInteractionService.execute(
      'ExecutiveNarrative',
      'Executive_Snapshot__c',
      snapshotId,
      null
    );
    if (!result.success) {
      throw new PartnerSyncHandledException(
        'Unable to generate a narrative: ' + result.errorMessage
      );
    }

    snapshot.Narrative__c = result.responseText;
    snapshot.Narrative_Generated_On__c = System.now();
    Database.update(snapshot, AccessLevel.SYSTEM_MODE);

    return snapshot;
  }
}
