/**
 * Selector that finds other deal registrations that may be conflict candidates for a given
 * deal, matched either by shared customer account or by customer identity fingerprint.
 */
public without sharing class DealConflictCandidateSelector {
  /**
   * Lightweight projection of a candidate deal registration considered during conflict analysis.
   */
  public class Candidate {
    public Id dealId;
    public Id customerAccountId;
    public Id opportunityId;
    public String identityFingerprint;
    public Date protectionEndDate;
  }

  @SuppressWarnings('PMD.ApexCRUDViolation')
  /**
   * Queries other open deal registrations that share the deal's customer account or customer
   * identity fingerprint, as candidates for conflict analysis.
   *
   * @param context Conflict analysis context, carrying the deal being analyzed and its identity.
   * @return Up to 200 candidate deal registrations.
   */
  public static List<Candidate> selectCandidates(DealConflictContext context) {
    List<Candidate> results = new List<Candidate>();
    for (Deal_Registration__c row : [
      SELECT
        Id,
        Customer_Account__c,
        Opportunity__c,
        Customer_Identity_Fingerprint__c,
        Protection_End_Date__c
      FROM Deal_Registration__c
      WHERE
        Id != :context.deal.Id
        AND Status__c IN ('Submitted', 'Under Review', 'Approved')
        AND (Customer_Account__c = :context.deal.Customer_Account__c
        OR Customer_Identity_Fingerprint__c = :context.identity.fingerprint)
      LIMIT 200
    ]) {
      Candidate candidate = new Candidate();
      candidate.dealId = row.Id;
      candidate.customerAccountId = row.Customer_Account__c;
      candidate.opportunityId = row.Opportunity__c;
      candidate.identityFingerprint = row.Customer_Identity_Fingerprint__c;
      candidate.protectionEndDate = row.Protection_End_Date__c;
      results.add(candidate);
    }
    return results;
  }
}
