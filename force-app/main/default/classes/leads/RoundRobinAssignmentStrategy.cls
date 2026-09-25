/**
 * Selects whichever eligible partner has gone longest without receiving a
 * lead, using assignment history rather than a separate "next in line"
 * counter object. A partner with no prior assignment is picked immediately
 * (in candidate-list order), since they have no history to compare.
 */
public without sharing class RoundRobinAssignmentStrategy implements LeadAssignmentStrategy {
  public Id selectPartner(List<Id> candidatePartnerAccountIds) {
    if (
      candidatePartnerAccountIds == null || candidatePartnerAccountIds.isEmpty()
    ) {
      return null;
    }

    Map<Id, Datetime> lastAssignedByPartner = new Map<Id, Datetime>();
    for (AggregateResult row : [
      SELECT
        Partner_Account__c partnerAccountId,
        MAX(Assigned_On__c) lastAssignedOn
      FROM Partner_Lead_Assignment__c
      WHERE Partner_Account__c IN :candidatePartnerAccountIds
      WITH SYSTEM_MODE
      GROUP BY Partner_Account__c
    ]) {
      lastAssignedByPartner.put(
        (Id) row.get('partnerAccountId'),
        (Datetime) row.get('lastAssignedOn')
      );
    }

    Id selected;
    Datetime earliestAssignedOn;
    for (Id candidateId : candidatePartnerAccountIds) {
      Datetime lastAssignedOn = lastAssignedByPartner.get(candidateId);
      if (lastAssignedOn == null) {
        return candidateId;
      }
      if (earliestAssignedOn == null || lastAssignedOn < earliestAssignedOn) {
        earliestAssignedOn = lastAssignedOn;
        selected = candidateId;
      }
    }
    return selected;
  }
}
