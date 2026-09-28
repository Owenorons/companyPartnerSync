/**
 * Finds bounded, relevant evidence rows for a governed AI use case, from
 * AI_Grounding_Source__mdt configuration - a SOQL relevance lookup against
 * a record the running user can already see, never embeddings/vector
 * search (Known Adaptation). Supports a fixed set of (related object,
 * source object) pairs via an explicit branch, the same static-SOQL
 * tradeoff IntelligenceContextService/PartnerShareService already accept.
 * Results are candidates only - AIInteractionService persists AI_Evidence__c
 * rows only for whichever candidates were actually included in a call.
 */
public without sharing class GroundingService {
  public class Evidence {
    public String sourceObject;
    public Id sourceRecordId;
    public String excerpt;
  }

  /**
   * Finds candidate evidence for a use case and related record.
   *
   * @param useCaseKey The governed use case (matches AI_Grounding_Source__mdt.Use_Case_Key__c).
   * @param relatedObject The SObject API name of the related record.
   * @param relatedRecordId Id of the related record to ground against.
   * @return Up to Max_Results__c candidate evidence rows, or an empty list if no policy matches.
   */
  public static List<Evidence> findEvidence(
    String useCaseKey,
    String relatedObject,
    Id relatedRecordId
  ) {
    List<Evidence> results = new List<Evidence>();
    if (
      String.isBlank(useCaseKey) ||
      String.isBlank(relatedObject) ||
      relatedRecordId == null
    ) {
      return results;
    }

    List<AI_Grounding_Source__mdt> sources = [
      SELECT Source_Object__c, Max_Results__c
      FROM AI_Grounding_Source__mdt
      WHERE Active__c = TRUE AND Use_Case_Key__c = :useCaseKey
      WITH SYSTEM_MODE
    ];

    for (AI_Grounding_Source__mdt source : sources) {
      Integer maxResults = source.Max_Results__c == null
        ? 5
        : Integer.valueOf(source.Max_Results__c);
      if (
        relatedObject == 'Partner_Renewal__c' &&
        source.Source_Object__c == 'Customer_Success_Risk__c'
      ) {
        results.addAll(findRenewalRiskEvidence(relatedRecordId, maxResults));
      }
      // No other (relatedObject, Source_Object__c) pair is wired to a real
      // query yet - an unmatched but Active configuration row is silently
      // skipped rather than guessed at, matching PartnerShareService's
      // "unsupported target" handling for the analogous situation.
    }
    return results;
  }

  private static List<Evidence> findRenewalRiskEvidence(
    Id renewalId,
    Integer maxResults
  ) {
    List<Evidence> results = new List<Evidence>();
    List<Partner_Renewal__c> renewals = [
      SELECT Customer_Success_Engagement__c
      FROM Partner_Renewal__c
      WHERE Id = :renewalId
      WITH SYSTEM_MODE
    ];
    if (
      renewals.isEmpty() || renewals[0].Customer_Success_Engagement__c == null
    ) {
      return results;
    }

    for (Customer_Success_Risk__c risk : [
      SELECT Risk_Type__c, Severity__c, Description__c
      FROM Customer_Success_Risk__c
      WHERE
        Customer_Success_Engagement__c = :renewals[0]
          .Customer_Success_Engagement__c
        AND Status__c NOT IN ('Resolved', 'Accepted', 'Closed')
      WITH SYSTEM_MODE
      ORDER BY CreatedDate DESC
      LIMIT :maxResults
    ]) {
      Evidence evidence = new Evidence();
      evidence.sourceObject = 'Customer_Success_Risk__c';
      evidence.sourceRecordId = risk.Id;
      evidence.excerpt =
        risk.Severity__c +
        ' ' +
        risk.Risk_Type__c +
        ': ' +
        risk.Description__c;
      results.add(evidence);
    }
    return results;
  }
}
