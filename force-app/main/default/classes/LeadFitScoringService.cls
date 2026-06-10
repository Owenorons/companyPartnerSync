public with sharing class LeadFitScoringService {
  //AI Engine 1

  //Purpose: Score partner leads for conversion fit.
  /***
   * How likely is partner to convert lead?
   *
   *
   *
   * **/

  //Input
  /***
     * Lead Age

     Partner Win Rate

     Partner Tier

     Industry Match

     Previous Revenue
     */

  //Output
  // Score (0-100)

  // Example
  public static Decimal score(Lead lead) {
    Decimal score = 50;

    if (lead.Industry == 'Healthcare') {
      score += 10;
    }

    return score;
  }
}
