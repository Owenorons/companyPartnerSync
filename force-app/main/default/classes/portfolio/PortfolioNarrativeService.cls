/**
 * Generates an optional, explicit, internally-triggered AI narrative
 * summarizing a Partner_Portfolio_Snapshot__c's own already-computed
 * numbers - never raw partner records (doc's "bounded narrative, not
 * raw-record analysis" invariant, enforced structurally: the
 * PortfolioNarrative use case's AI_Context_Policy__mdt only allows fields
 * on Partner_Portfolio_Snapshot__c itself). Never runs automatically as
 * part of PartnerPortfolioSnapshotBatch.
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class PortfolioNarrativeService {
  /**
   * Generates and persists a narrative for a snapshot.
   *
   * @param snapshotId Id of the Partner_Portfolio_Snapshot__c to summarize.
   * @return The updated snapshot.
   */
  public static Partner_Portfolio_Snapshot__c generateNarrative(Id snapshotId) {
    PartnerAccessService.assertInternalUser();
    if (snapshotId == null) {
      throw new PartnerSyncHandledException(
        'A portfolio snapshot is required.'
      );
    }
    List<Partner_Portfolio_Snapshot__c> rows = [
      SELECT Partner_Account__c, Narrative__c, Narrative_Generated_On__c
      FROM Partner_Portfolio_Snapshot__c
      WHERE Id = :snapshotId
      WITH SYSTEM_MODE
    ];
    if (rows.isEmpty()) {
      throw new PartnerSyncHandledException('Portfolio snapshot not found.');
    }
    Partner_Portfolio_Snapshot__c snapshot = rows[0];

    AIInteractionService.InteractionResult result = AIInteractionService.execute(
      'PortfolioNarrative',
      'Partner_Portfolio_Snapshot__c',
      snapshotId,
      snapshot.Partner_Account__c
    );
    if (!result.success) {
      throw new PartnerSyncHandledException(
        'Unable to generate a narrative: ' + result.errorMessage
      );
    }

    snapshot.Narrative__c = result.responseText;
    snapshot.Narrative_Generated_On__c = System.now();
    Database.update(snapshot, AccessLevel.SYSTEM_MODE);

    PlatformEventPublisherService.publish(
      'PortfolioSnapshotComputed',
      snapshot.Id,
      'Partner_Portfolio_Snapshot__c',
      snapshot.Partner_Account__c,
      'A portfolio snapshot narrative was generated.',
      'Info'
    );

    return snapshot;
  }
}
