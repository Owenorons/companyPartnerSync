public with sharing class DealRiskScoringService {
  /* AI Engine 2 

  Purpose: Probability deal fails
Inputs:
Deal Size

Competition

Sales Cycle Length

Conflict History

Partner Health

Output:
Low
Medium
High
*/

  //Example:
  public static Decimal score(Deal_Registration__c deal) {
    Decimal score = 0;

    if (deal.Conflict_Status__c == 'Potential Conflict') {
      score += 40;
    }

    return score;
  }
}
