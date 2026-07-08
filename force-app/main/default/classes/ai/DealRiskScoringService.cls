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

  public static Decimal score(Deal_Registration__c deal) {
    return score(deal, new List<Deal_Registration__c>());
  }

  public static Decimal score(
    Deal_Registration__c deal,
    List<Deal_Registration__c> conflicts
  ) {
    Decimal score = 0;

    if (deal.Conflict_Status__c == 'Potential Conflict') {
      score += 35;
    } else if (deal.Conflict_Status__c == 'Confirmed Conflict') {
      score += 50;
    }

    Integer conflictCount = conflicts == null ? 0 : conflicts.size();
    score += Math.min(conflictCount * 10, 30);

    Decimal revenue = deal.Estimated_Revenue__c == null
      ? 0
      : deal.Estimated_Revenue__c;

    if (revenue >= 250000) {
      score += 20;
    } else if (revenue >= 100000) {
      score += 12;
    } else if (revenue >= 50000) {
      score += 6;
    }

    if (deal.Estimated_Close_Date__c != null) {
      Integer daysToClose = Date.today()
        .daysBetween(deal.Estimated_Close_Date__c);

      if (daysToClose < 0) {
        score += 15;
      } else if (daysToClose <= 30) {
        score += 8;
      }
    }

    if (
      String.isBlank(deal.Business_Problem__c) ||
      String.isBlank(deal.Proposed_Solution__c)
    ) {
      score += 10;
    }

    if (deal.Status__c == 'Rejected') {
      score += 15;
    }

    return score > 100 ? 100 : score;
  }

  public static String level(Decimal score) {
    if (score >= 70) {
      return 'High';
    }

    if (score >= 35) {
      return 'Medium';
    }

    return 'Low';
  }

  public static String summary(
    Deal_Registration__c deal,
    List<Deal_Registration__c> conflicts,
    Decimal score
  ) {
    List<String> signals = new List<String>();

    if (
      deal.Conflict_Status__c == 'Potential Conflict' ||
      deal.Conflict_Status__c == 'Confirmed Conflict'
    ) {
      signals.add('conflict status is ' + deal.Conflict_Status__c);
    }

    Integer conflictCount = conflicts == null ? 0 : conflicts.size();

    if (conflictCount > 0) {
      signals.add(
        String.valueOf(conflictCount) + ' related active registration(s)'
      );
    }

    if (
      deal.Estimated_Revenue__c != null &&
      deal.Estimated_Revenue__c >= 100000
    ) {
      signals.add('high estimated revenue');
    }

    if (deal.Estimated_Close_Date__c != null) {
      Integer daysToClose = Date.today()
        .daysBetween(deal.Estimated_Close_Date__c);

      if (daysToClose < 0) {
        signals.add('estimated close date has passed');
      } else if (daysToClose <= 30) {
        signals.add('close date is within 30 days');
      }
    }

    if (
      String.isBlank(deal.Business_Problem__c) ||
      String.isBlank(deal.Proposed_Solution__c)
    ) {
      signals.add('qualification details are incomplete');
    }

    if (signals.isEmpty()) {
      return 'Risk is based on submitted deal data and no material risk signals were found.';
    }

    return 'Risk is based on submitted deal data: ' +
      String.join(signals, ', ') +
      '.';
  }

  public static String recommendation(
    Deal_Registration__c deal,
    List<Deal_Registration__c> conflicts,
    Decimal score
  ) {
    if (deal.Status__c == 'Rejected') {
      return String.isBlank(deal.Rejection_Reason__c)
        ? 'Review the rejection decision before taking further action.'
        : deal.Rejection_Reason__c;
    }

    if (score >= 70) {
      return 'Investigate conflicts and qualification evidence before approving protection.';
    }

    if (score >= 35) {
      return 'Review submitted evidence and related registrations before making a decision.';
    }

    return 'Proceed based on qualification, partner fit, and submitted evidence.';
  }
}
