AI Engine 1
LeadFitScoringService.cls
Purpose:
How likely is partner to convert lead?
Inputs
Lead Age

Partner Win Rate

Partner Tier

Industry Match

Previous Revenue
Output
0 - 100
Example
public static Decimal score(
Lead lead
) {
Decimal score = 50;

    if (
        lead.Industry == 'Healthcare'
    ) {
        score += 10;
    }

    return score;

}
AI Engine 2
DealRiskScoringService.cls
Purpose:
Probability deal fails
Inputs
Deal Size

Competition

Sales Cycle Length

Conflict History

Partner Health
Output
Low
Medium
High
Example
public static Decimal score(
Deal_Registration\_\_c deal
) {
Decimal score = 0;

    if (
        deal.Conflict_Status__c ==
        'Potential Conflict'
    ) {
        score += 40;
    }

    return score;

}
AI Engine 3
PartnerHealthScoringService.cls
Purpose:
Measure partner quality
Inputs
Lead Acceptance %

Lead Conversion %

Revenue

MDF ROI

Content Engagement
Output
0 - 100
Example
public static Decimal calculate(
Id partnerAccountId
) {
return 87;
}
AI Engine 4
NextBestActionService.cls
Purpose:
Generate recommendations
Example Outputs
Register more healthcare opportunities.

Submit MDF request for Q4 campaign.

Follow up 3 stalled opportunities.

Download latest campaign assets.
Insight Generator
AIInsightGeneratorService.cls
Creates:
AI_Insight**c
records.
Example
AI_Insight**c insight =
new AI_Insight\_\_c();

insight.Insight_Type\_\_c =
'Lead Score';

insight.Score\_\_c =
leadScore;

insight.Confidence\_\_c =
82;

insight.Recommendation\_\_c =
'Prioritize this lead.';

insight.Model_Name\_\_c =
'PartnerSync Lead Scoring';

insight.Model_Version\_\_c =
'1.0';
Experience Cloud Components
Create:
psAiInsightPanel
psAiInsightCard
psPartnerNextBestActions
psAiInsightPanel
Displays:
Lead Score

Deal Risk

Partner Health

MDF ROI
psPartnerNextBestActions
Displays:
Recommended Actions
Priority
Impact
Confidence
Security Rules
Partner:
Only own AI insights
Internal:
All insights
Use:
PartnerRecordAccessService
Audit Integration
Whenever AI creates insight:
AuditFactory.createSuccess(
'AI Insight',
insight.Id,
'Insight Generated'
);
Whenever recommendation accepted:
Action:
AI Recommendation Accepted
Future AI Roadmap
Phase 1
Rule-based scoring
Lead Score
Deal Risk
Partner Health
Phase 2
Einstein / Agentforce Integration
Predictive Lead Score

Predictive Deal Score

Partner Churn Prediction
Phase 3
External AI
Azure OpenAI
OpenAI
Anthropic
Vertex AI
using Named Credentials.
Experience Cloud AI UX
Partner sees:
Health Score: 87

Recommendation:
Focus on healthcare leads.
Internal team sees:
Partner Risk
Deal Risk
MDF ROI Forecast
Sprint 14 Pack 9 Deliverables
✔ AI_Insight\_\_c

✔ AIInsightDTO
✔ AIInsightRequestDTO

✔ AIInsightSelector
✔ AIInsightDomain
✔ AIInsightService
✔ PartnerAIController

✔ LeadFitScoringService
✔ DealRiskScoringService
✔ PartnerHealthScoringService
✔ NextBestActionService

✔ AIInsightGeneratorService

✔ AI Experience Cloud Components

✔ Audit Integration
Sprint 14 Complete
At this point we have completed:
Pack 1 - Core Foundation
Pack 2 - Partner Onboarding
Pack 3 - Lead Distribution
Pack 4 - Lead Conversion + Deal Registration
Pack 5 - Deal Review
Pack 6 - Security Framework
Pack 7 - Audit Framework
Pack 8 - Notification Framework
Pack 9 - AI Foundation
