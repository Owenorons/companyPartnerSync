public without sharing class DealConflictCandidateSelector {
  public class Candidate {
    public Id dealId;
    public Id customerAccountId;
    public Id opportunityId;
    public String identityFingerprint;
    public Date protectionEndDate;
  }

  @SuppressWarnings('PMD.ApexCRUDViolation')
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
