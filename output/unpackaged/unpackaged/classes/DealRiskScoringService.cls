/**
 * Rules-based (non-LLM) deal risk scoring engine ("AI Engine 2"): scores
 * a Deal_Registration__c from 0-100 using conflict status/count,
 * revenue, close-date proximity, and qualification completeness, then
 * buckets the score into Low/Medium/High via level(). No AIProvider
 * callout is involved despite the "AI Engine" naming used elsewhere.
 */
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

  /**
   * Scores a deal registration's risk with no known conflicting
   * registrations, equivalent to calling the two-argument overload with
   * an empty conflicts list.
   *
   * @param deal The deal registration to score.
   * @return A risk score from 0 to 100.
   */
  public static Decimal score(Deal_Registration__c deal) {
    return score(deal, new List<Deal_Registration__c>());
  }

  /**
   * Scores a deal registration's risk from 0-100 using conflict
   * status/count, estimated revenue, close-date proximity, and
   * qualification completeness.
   *
   * @param deal The deal registration to score.
   * @param conflicts Related active registrations flagged as conflicts for this deal.
   * @return A risk score from 0 to 100.
   */
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

  /**
   * Buckets a numeric risk score into a display level.
   *
   * @param score A risk score from 0 to 100, as produced by score().
   * @return 'High' (>= 70), 'Medium' (>= 35), or 'Low'.
   */
  public static String level(Decimal score) {
    // Cutoffs mirror the point allocations in score() above - if those
    // weights change, revisit these thresholds or High/Medium/Low will
    // drift out of sync with the underlying point scale.
    if (score >= 70) {
      return 'High';
    }

    if (score >= 35) {
      return 'Medium';
    }

    return 'Low';
  }

  /**
   * Builds a human-readable summary of the risk signals found for a deal
   * (conflicts, revenue, close-date proximity, qualification gaps).
   *
   * @param deal The deal registration being summarized.
   * @param conflicts Related active registrations flagged as conflicts for this deal.
   * @param score The deal's computed risk score (unused directly; included for symmetry with score/level/recommendation callers).
   * @return A sentence describing the risk signals found, or a fallback sentence if none were found.
   */
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

  /**
   * Recommends a next action for a deal based on its status and risk score.
   *
   * @param deal The deal registration being evaluated.
   * @param conflicts Related active registrations flagged as conflicts for this deal (unused directly; included for symmetry with score/level/summary callers).
   * @param score The deal's computed risk score.
   * @return The rejection reason if the deal was rejected, otherwise a recommendation graded by risk score.
   */
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
