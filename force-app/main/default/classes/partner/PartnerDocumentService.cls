/** Controlled evidence orchestration. File binaries remain in Salesforce Files. */
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class PartnerDocumentService {
  /**
   * Generates (via upsert on the requirement key) the set of document
   * requirements that apply to an onboarding, based on active
   * Partner_Document_Requirement_Rule__mdt rules matching the underlying
   * application's requested tier, partner type and country.
   *
   * @param onboardingId Id of the Partner_Onboarding__c record to generate requirements for.
   * @return The document requirement records that were generated.
   */
  public static List<Partner_Document_Requirement__c> generateRequirements(
    Id onboardingId
  ) {
    Partner_Onboarding__c onboarding = [
      SELECT
        Id,
        Application__r.Requested_Tier__c,
        Application__r.Partner_Type__c,
        Application__r.Country__c
      FROM Partner_Onboarding__c
      WHERE Id = :onboardingId
      LIMIT 1
    ];
    List<Partner_Document_Requirement__c> generated = new List<Partner_Document_Requirement__c>();
    for (Partner_Document_Requirement_Rule__mdt rule : [
      SELECT
        DeveloperName,
        Requested_Tier__c,
        Partner_Type__c,
        Country__c,
        Document_Type__c,
        Requirement_Level__c,
        Gate__c,
        Blocking__c,
        Waiver_Eligible__c,
        Due_Days__c
      FROM Partner_Document_Requirement_Rule__mdt
      WHERE Active__c = TRUE
    ]) {
      if (
        !matches(
          rule.Requested_Tier__c,
          onboarding.Application__r.Requested_Tier__c
        ) ||
        !matches(
          rule.Partner_Type__c,
          onboarding.Application__r.Partner_Type__c
        ) ||
        !matches(rule.Country__c, onboarding.Application__r.Country__c)
      ) {
        continue;
      }
      generated.add(
        new Partner_Document_Requirement__c(
          Onboarding__c = onboarding.Id,
          Requirement_Key__c = String.valueOf(onboarding.Id) +
            ':' +
            rule.DeveloperName,
          Document_Type__c = rule.Document_Type__c,
          Requirement_Level__c = rule.Requirement_Level__c,
          Gate__c = rule.Gate__c,
          Status__c = 'Awaiting Submission',
          Blocking__c = rule.Blocking__c,
          Waiver_Eligible__c = rule.Waiver_Eligible__c,
          Due_On__c = Date.today()
            .addDays(
              rule.Due_Days__c == null ? 14 : rule.Due_Days__c.intValue()
            ),
          Source_Rule__c = rule.DeveloperName
        )
      );
    }
    if (!generated.isEmpty()) {
      Database.upsert(
        generated,
        Partner_Document_Requirement__c.Fields.Requirement_Key__c,
        AccessLevel.SYSTEM_MODE
      );
    }
    return generated;
  }

  /**
   * Records a partner's submission of a document against a requirement,
   * versioning it after any prior submissions for the same requirement.
   * Idempotent on submissionKey: a repeat call with the same key returns the
   * already-recorded submission instead of creating a duplicate.
   *
   * @param requirementId Id of the Partner_Document_Requirement__c this submission satisfies.
   * @param contentDocumentId Id of the ContentDocument holding the uploaded file.
   * @param submissionKey Idempotency key identifying this submission attempt.
   * @param confidentiality Confidentiality level for the document; defaults to 'Partner' when blank.
   * @return The submitted (or previously recorded) Partner_Document__c record.
   */
  public static Partner_Document__c submitDocument(
    Id requirementId,
    String contentDocumentId,
    String submissionKey,
    String confidentiality
  ) {
    if (String.isBlank(contentDocumentId) || String.isBlank(submissionKey)) {
      throw new IllegalArgumentException(
        'Content document id and submission key are required.'
      );
    }
    List<Partner_Document__c> existing = [
      SELECT Id, Requirement__c, Onboarding__c, Status__c, Version_Number__c
      FROM Partner_Document__c
      WHERE Submission_Key__c = :submissionKey
      LIMIT 1
    ];
    if (!existing.isEmpty())
      return existing[0];

    Partner_Document_Requirement__c requirement = [
      SELECT Id, Onboarding__c
      FROM Partner_Document_Requirement__c
      WHERE Id = :requirementId
      LIMIT 1
    ];
    AggregateResult versionResult = [
      SELECT MAX(Version_Number__c) maximum
      FROM Partner_Document__c
      WHERE Requirement__c = :requirementId
    ];
    Decimal maximum = (Decimal) versionResult.get('maximum');
    Partner_Document__c document = new Partner_Document__c(
      Requirement__c = requirement.Id,
      Onboarding__c = requirement.Onboarding__c,
      Content_Document_Id__c = contentDocumentId,
      Submission_Key__c = submissionKey,
      Version_Number__c = maximum == null ? 1 : maximum + 1,
      Status__c = 'Submitted',
      Confidentiality__c = String.isBlank(confidentiality)
        ? 'Partner'
        : confidentiality,
      Submitted_On__c = System.now()
    );
    Database.insert(document, AccessLevel.SYSTEM_MODE);
    Database.update(
      new Partner_Document_Requirement__c(
        Id = requirement.Id,
        Status__c = 'Submitted'
      ),
      AccessLevel.SYSTEM_MODE
    );
    return document;
  }

  /**
   * Records a reviewer's decision (Accepted/Rejected/Replacement Required)
   * on a submitted document, updating the document and its requirement to
   * match. Idempotent on reviewKey: a repeat call with the same key returns
   * the already-recorded review instead of creating a duplicate.
   *
   * @param documentId Id of the Partner_Document__c record being reviewed.
   * @param outcome The review outcome: 'Accepted', 'Rejected', or 'Replacement Required'.
   * @param reason Explanation for the outcome; required unless outcome is 'Accepted'.
   * @param reviewKey Idempotency key identifying this review attempt.
   * @return The recorded (or previously recorded) Partner_Document_Review__c record.
   */
  public static Partner_Document_Review__c reviewDocument(
    Id documentId,
    String outcome,
    String reason,
    String reviewKey
  ) {
    if (
      !new Set<String>{ 'Accepted', 'Rejected', 'Replacement Required' }
        .contains(outcome)
    ) {
      throw new IllegalArgumentException(
        'Unsupported document review outcome.'
      );
    }
    if (outcome != 'Accepted' && String.isBlank(reason)) {
      throw new IllegalArgumentException(
        'A reason is required for rejection or replacement.'
      );
    }
    List<Partner_Document_Review__c> existing = [
      SELECT Id, Document__c, Outcome__c, Reason__c, Reviewer__c, Reviewed_On__c
      FROM Partner_Document_Review__c
      WHERE Review_Key__c = :reviewKey
      LIMIT 1
    ];
    if (!existing.isEmpty())
      return existing[0];

    Partner_Document__c document = [
      SELECT Id, Requirement__c
      FROM Partner_Document__c
      WHERE Id = :documentId
      LIMIT 1
      FOR UPDATE
    ];
    Partner_Document_Review__c review = new Partner_Document_Review__c(
      Document__c = document.Id,
      Outcome__c = outcome,
      Reason__c = reason,
      Reviewer__c = UserInfo.getUserId(),
      Reviewed_On__c = System.now(),
      Review_Key__c = reviewKey
    );
    Database.insert(review, AccessLevel.SYSTEM_MODE);
    document.Status__c = outcome;
    Database.update(document, AccessLevel.SYSTEM_MODE);
    String requirementStatus = outcome == 'Rejected'
      ? 'Replacement Required'
      : outcome;
    Database.update(
      new Partner_Document_Requirement__c(
        Id = document.Requirement__c,
        Status__c = requirementStatus
      ),
      AccessLevel.SYSTEM_MODE
    );
    return review;
  }

  private static Boolean matches(String configured, String actual) {
    return String.isBlank(configured) || configured == actual;
  }
}
