/** Explainable, configurable partner performance score derived from PartnerSync KPIs. */
@SuppressWarnings('PMD.ApexCRUDViolation')
public with sharing class PartnerHealthScoringService {
  private static final Set<String> ASSIGNABLE_TIERS = new Set<String>{
    'Silver',
    'Gold',
    'Platinum',
    'Strategic'
  };

  public static Decimal calculate(Id partnerAccountId) {
    if (partnerAccountId == null) {
      throw new PartnerSyncHandledException('A partner account is required.');
    }
    PartnerKPIDTO kpi = AnalyticsDomain.calculatePartnerKPI(
      AnalyticsSelector.selectPartnerLeads(partnerAccountId),
      AnalyticsSelector.selectPartnerDeals(partnerAccountId),
      AnalyticsSelector.selectPartnerOpportunities(partnerAccountId),
      AnalyticsSelector.selectPartnerBudget(partnerAccountId)
    );
    return kpi.healthScore;
  }

  /** Subscriber-configured weights are normalised to a safe 0-100 result. */
  public static Decimal calculate(PartnerKPIDTO kpi) {
    if (kpi == null)
      return 0;
    ScoreWeights weights = scoreWeights();
    Decimal score =
      (bounded(kpi.leadAcceptanceRate) * weights.leadAcceptance) +
      (bounded(kpi.leadConversionRate) * weights.leadConversion) +
      (bounded(kpi.dealWinRate) * weights.dealWin) +
      (ratio(kpi.totalRevenue, kpi.totalPipeline) * weights.revenue) +
      (bounded(kpi.mdfUtilisationRate) * weights.mdf);
    return score.setScale(0);
  }

  public static String healthLabel(Decimal score) {
    Decimal value = score == null ? 0 : score;
    if (value >= 80)
      return 'Thriving';
    if (value >= 60)
      return 'Healthy';
    if (value >= 40)
      return 'Developing';
    return 'Needs Attention';
  }

  /** Tier thresholds come from assignable Partner_Tier__mdt records. */
  public static String recommendTier(Decimal score) {
    Decimal value = score == null ? 0 : score;
    for (Partner_Tier__mdt tier : [
      SELECT Tier_Name__c, Minimum_Score__c
      FROM Partner_Tier__mdt
      WHERE Tier_Name__c IN :ASSIGNABLE_TIERS
      ORDER BY Minimum_Score__c DESC
    ]) {
      if (tier.Minimum_Score__c != null && value >= tier.Minimum_Score__c) {
        return tier.Tier_Name__c;
      }
    }
    return 'Silver';
  }

  public static List<String> explain(PartnerKPIDTO kpi) {
    List<String> signals = new List<String>();
    if (kpi == null) {
      signals.add('Partner activity is not yet available.');
      return signals;
    }
    ScoreWeights weights = scoreWeights();
    signals.add(
      signal(
        percent(kpi.leadAcceptanceRate),
        'lead acceptance',
        weights.leadAcceptance
      )
    );
    signals.add(
      signal(
        percent(kpi.leadConversionRate),
        'lead conversion',
        weights.leadConversion
      )
    );
    signals.add(
      signal(percent(kpi.dealWinRate), 'deal win rate', weights.dealWin)
    );
    signals.add(
      signal(
        percent(ratio(kpi.totalRevenue, kpi.totalPipeline)),
        'pipeline realisation',
        weights.revenue
      )
    );
    signals.add(
      signal(percent(kpi.mdfUtilisationRate), 'MDF utilisation', weights.mdf)
    );
    return signals;
  }

  private static String signal(String value, String label, Decimal weight) {
    return value +
      ' ' +
      label +
      ' contributes up to ' +
      String.valueOf(weight.setScale(0)) +
      ' points.';
  }

  private static Decimal ratio(Decimal numerator, Decimal denominator) {
    Decimal safeNumerator = numerator == null ? 0 : numerator;
    Decimal safeDenominator = denominator == null ? 0 : denominator;
    return safeDenominator <= 0 ? 0 : bounded(safeNumerator / safeDenominator);
  }

  private static Decimal bounded(Decimal value) {
    if (value == null || value < 0)
      return 0;
    return value > 1 ? 1 : value;
  }

  private static String percent(Decimal value) {
    return String.valueOf((bounded(value) * 100).setScale(0)) + '%';
  }

  private static ScoreWeights scoreWeights() {
    Tenant_Config__mdt config = Tenant_Config__mdt.getInstance('Default');
    ScoreWeights weights = new ScoreWeights();
    weights.leadAcceptance = configured(
      config == null ? null : config.Health_Lead_Acceptance_Weight__c,
      20
    );
    weights.leadConversion = configured(
      config == null ? null : config.Health_Lead_Conversion_Weight__c,
      25
    );
    weights.dealWin = configured(
      config == null ? null : config.Health_Deal_Win_Weight__c,
      30
    );
    weights.revenue = configured(
      config == null ? null : config.Health_Revenue_Weight__c,
      20
    );
    weights.mdf = configured(
      config == null ? null : config.Health_MDF_Weight__c,
      5
    );
    Decimal total =
      weights.leadAcceptance +
      weights.leadConversion +
      weights.dealWin +
      weights.revenue +
      weights.mdf;
    Decimal normaliser = total <= 0 ? 1 : 100 / total;
    weights.leadAcceptance *= normaliser;
    weights.leadConversion *= normaliser;
    weights.dealWin *= normaliser;
    weights.revenue *= normaliser;
    weights.mdf *= normaliser;
    return weights;
  }

  private static Decimal configured(Decimal value, Decimal fallback) {
    return value == null || value < 0 ? fallback : value;
  }

  private class ScoreWeights {
    Decimal leadAcceptance;
    Decimal leadConversion;
    Decimal dealWin;
    Decimal revenue;
    Decimal mdf;
  }
}
