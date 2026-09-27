/**
 * Request payload shared by every Deal_Opportunity__c command
 * (linkOpportunityToDeal/createOpportunityForDeal/unlinkOpportunityFromDeal/
 * setPrimaryOpportunity/markOpportunityRelationshipHistorical on
 * DealOpportunityCommandService), each using only the fields its action needs.
 */
public class DealOpportunityCommand {
  public Id dealId;
  public Id opportunityId;
  public String relationshipType;

  // Required for unlinkOpportunityFromDeal/setPrimaryOpportunity/
  // markOpportunityRelationshipHistorical - identifies the specific
  // Deal_Opportunity__c row being mutated.
  public Id dealOpportunityId;
  public Integer expectedVersion;
  public String reason;
}
