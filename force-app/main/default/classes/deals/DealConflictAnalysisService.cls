// Internal conflict findings must cross partner sharing boundaries. Only the
// restricted Candidate projection leaves the privileged selector. NOPMD
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class DealConflictAnalysisService {
  private static final String RULE_SET_VERSION = '1.0';

  public static DealConflictDTO analyze(DealConflictContext context) {
    String inputHash = buildInputHash(context);
    List<Deal_Conflict_Analysis_Run__c> currentRuns = [
      SELECT Id, Input_Hash__c
      FROM Deal_Conflict_Analysis_Run__c
      WHERE Deal__c = :context.deal.Id AND Current__c = TRUE
      LIMIT 1
    ];
    if (!currentRuns.isEmpty() && currentRuns[0].Input_Hash__c == inputHash) {
      return resultForRun(currentRuns[0].Id);
    }
    supersede(currentRuns);

    Deal_Conflict_Analysis_Run__c run = new Deal_Conflict_Analysis_Run__c(
      Deal__c = context.deal.Id,
      Rule_Set_Version__c = RULE_SET_VERSION,
      Input_Hash__c = inputHash,
      Active_Run_Key__c = String.valueOf(context.deal.Id),
      Started_On__c = System.now(),
      Current__c = true,
      Status__c = 'Running'
    );
    Database.insert(run, AccessLevel.SYSTEM_MODE);

    Deal_Conflict_Scoring_Rule__mdt rule = [
      SELECT
        Conflict_Type__c,
        Rule_Version__c,
        Weight__c,
        Blocking_Threshold__c,
        Blocking__c
      FROM Deal_Conflict_Scoring_Rule__mdt
      WHERE Active__c = TRUE AND Conflict_Type__c = 'Existing Registration'
      WITH USER_MODE
      LIMIT 1
    ];
    List<Deal_Conflict__c> findings = new List<Deal_Conflict__c>();
    for (
      DealConflictCandidateSelector.Candidate candidate : DealConflictCandidateSelector.selectCandidates(
        context
      )
    ) {
      Decimal score = candidate.customerAccountId ==
        context.deal.Customer_Account__c
        ? 100
        : rule.Weight__c;
      findings.add(
        new Deal_Conflict__c(
          Deal__c = context.deal.Id,
          Analysis_Run__c = run.Id,
          Matched_Deal__c = candidate.dealId,
          Type__c = rule.Conflict_Type__c,
          Subtype__c = candidate.customerAccountId ==
            context.deal.Customer_Account__c
            ? 'Same Customer Account'
            : 'Identity Fingerprint',
          Severity__c = score >= 100 ? 'Critical' : 'High',
          Confidence__c = score,
          Match_Score__c = score,
          Blocking__c = rule.Blocking__c && score >= rule.Blocking_Threshold__c,
          Current__c = true,
          Status__c = 'Open',
          Rule_Version__c = rule.Rule_Version__c,
          Evidence_Summary__c = 'Structured customer identity matched an active registration.',
          Evidence_JSON__c = JSON.serialize(
            new Map<String, Object>{
              'sameCustomerAccount' => candidate.customerAccountId ==
              context.deal.Customer_Account__c,
              'fingerprintMatch' => candidate.identityFingerprint ==
              context.identity.fingerprint
            }
          ),
          Partner_Classification__c = 'Overlapping Registration',
          Partner_Message__c = 'This registration requires internal conflict review.',
          SLA_Due__c = System.now().addHours(24)
        )
      );
    }
    if (!findings.isEmpty())
      Database.insert(findings, AccessLevel.SYSTEM_MODE);
    run.Status__c = 'Completed';
    run.Completed_On__c = System.now();
    Database.update(run, AccessLevel.SYSTEM_MODE);
    return toResult(findings);
  }

  private static void supersede(List<Deal_Conflict_Analysis_Run__c> runs) {
    if (runs.isEmpty())
      return;
    Deal_Conflict_Analysis_Run__c oldRun = runs[0];
    oldRun.Current__c = false;
    oldRun.Active_Run_Key__c = null;
    oldRun.Status__c = 'Superseded';
    Database.update(oldRun, AccessLevel.SYSTEM_MODE);
    List<Deal_Conflict__c> oldFindings = [
      SELECT Id, Current__c, Status__c
      FROM Deal_Conflict__c
      WHERE Analysis_Run__c = :oldRun.Id AND Current__c = TRUE
    ];
    for (Deal_Conflict__c finding : oldFindings) {
      finding.Current__c = false;
      finding.Status__c = 'Superseded';
    }
    if (!oldFindings.isEmpty())
      Database.update(oldFindings, AccessLevel.SYSTEM_MODE);
  }

  private static DealConflictDTO resultForRun(Id runId) {
    return toResult(
      [
        SELECT Id, Matched_Deal__c
        FROM Deal_Conflict__c
        WHERE
          Analysis_Run__c = :runId
          AND Current__c = TRUE
          AND Blocking__c = TRUE
      ]
    );
  }

  private static DealConflictDTO toResult(List<Deal_Conflict__c> findings) {
    DealConflictDTO result = new DealConflictDTO();
    result.conflictingDealIds = new List<Id>();
    result.hasConflict = !findings.isEmpty();
    result.conflictStatus = result.hasConflict
      ? 'Potential Conflict'
      : 'No Conflict';
    result.summary = result.hasConflict
      ? 'Potential overlapping deal registrations detected.'
      : 'No conflicting deals found.';
    for (Deal_Conflict__c finding : findings) {
      if (finding.Matched_Deal__c != null)
        result.conflictingDealIds.add(finding.Matched_Deal__c);
    }
    return result;
  }

  private static String buildInputHash(DealConflictContext context) {
    String input =
      RULE_SET_VERSION +
      '|' +
      String.valueOf(context.deal.Customer_Account__c) +
      '|' +
      String.valueOf(context.deal.Opportunity__c) +
      '|' +
      context.identity.fingerprint;
    return EncodingUtil.convertToHex(
      Crypto.generateDigest('SHA-256', Blob.valueOf(input))
    );
  }
}
