/** Contracting aggregate and verified provider-event processing. */
public without sharing class PartnerAgreementService {
  /**
   * Creates a draft partner agreement once final approval for contracting
   * exists, or returns the existing agreement if one already exists for
   * the given key.
   *
   * @param onboardingId Id of the Partner_Onboarding__c the agreement
   * belongs to.
   * @param agreementType Type of agreement being created.
   * @param agreementKey Idempotency key identifying the agreement.
   * @param templateKey Key of the agreement template to use.
   * @param templateVersion Version of the agreement template to use.
   * @return The created or existing Partner_Agreement__c record.
   */
  public static Partner_Agreement__c createAgreement(
    Id onboardingId,
    String agreementType,
    String agreementKey,
    String templateKey,
    Decimal templateVersion
  ) {
    if (
      String.isBlank(agreementKey) ||
      String.isBlank(templateKey) ||
      templateVersion == null
    ) {
      throw new IllegalArgumentException(
        'Agreement key and versioned template are required.'
      );
    }
    Integer approvedPlans = [
      SELECT COUNT()
      FROM Partner_Approval_Plan__c
      WHERE
        Onboarding__c = :onboardingId
        AND Current__c = TRUE
        AND Status__c = 'Approved for Contracting'
      WITH SYSTEM_MODE
    ];
    if (approvedPlans == 0)
      throw new PartnerAgreementException(
        'Partner approval must be final before contracting.'
      );
    List<Partner_Agreement__c> existing = [
      SELECT Id, Status__c
      FROM Partner_Agreement__c
      WHERE Agreement_Key__c = :agreementKey
      WITH SYSTEM_MODE
      LIMIT 1
    ];
    if (!existing.isEmpty())
      return existing[0];
    Partner_Agreement__c agreement = new Partner_Agreement__c(
      Onboarding__c = onboardingId,
      Agreement_Key__c = agreementKey,
      Agreement_Type__c = agreementType,
      Status__c = 'Draft',
      Template_Key__c = templateKey,
      Template_Version__c = templateVersion
    );
    Database.insert(agreement, AccessLevel.SYSTEM_MODE);
    return agreement;
  }

  /**
   * Adds or updates a signatory on an agreement.
   *
   * @param agreementId Id of the Partner_Agreement__c the signatory
   * belongs to.
   * @param signatoryKey Idempotency key used to upsert the signatory.
   * @param signatoryName Name of the signatory.
   * @param email Email address of the signatory.
   * @param role Role of the signatory on the agreement.
   * @param signingOrder Order in which the signatory should sign.
   * @return The created or updated Partner_Agreement_Signatory__c record.
   */
  public static Partner_Agreement_Signatory__c addSignatory(
    Id agreementId,
    String signatoryKey,
    String signatoryName,
    String email,
    String role,
    Integer signingOrder
  ) {
    if (
      String.isBlank(signatoryKey) ||
      String.isBlank(signatoryName) ||
      String.isBlank(email)
    ) {
      throw new IllegalArgumentException('Signatory identity is required.');
    }
    Partner_Agreement__c agreement = [
      SELECT Id, Status__c
      FROM Partner_Agreement__c
      WHERE Id = :agreementId
      WITH SYSTEM_MODE
      LIMIT 1
      FOR UPDATE
    ];
    if (rank(agreement.Status__c) >= rank('Sent')) {
      throw new PartnerAgreementException(
        'Signatories cannot be changed once the agreement has been sent for signature.'
      );
    }
    Partner_Agreement_Signatory__c signatory = new Partner_Agreement_Signatory__c(
      Agreement__c = agreementId,
      Signatory_Key__c = signatoryKey,
      Name__c = signatoryName,
      Email__c = email,
      Role__c = role,
      Signing_Order__c = signingOrder,
      Status__c = 'Pending'
    );
    Database.upsert(
      signatory,
      Partner_Agreement_Signatory__c.Fields.Signatory_Key__c,
      AccessLevel.SYSTEM_MODE
    );
    return signatory;
  }

  /**
   * Sends an approved agreement to the active e-signature provider and
   * releases it, recording the resulting envelope reference. This is the
   * orchestration entry point that actually calls out to a provider;
   * releaseForSignature remains available directly for callers that
   * already hold a provider-issued envelope id (e.g. a manual or
   * provider-side reconciliation path).
   *
   * @param agreementId Id of the Partner_Agreement__c to send.
   * @return The updated Partner_Agreement__c record, now in Sent status.
   */
  public static Partner_Agreement__c sendForSignature(Id agreementId) {
    Partner_Agreement__c agreement = [
      SELECT Id, Status__c, Template_Key__c
      FROM Partner_Agreement__c
      WHERE Id = :agreementId
      WITH SYSTEM_MODE
      LIMIT 1
      FOR UPDATE
    ];
    if (agreement.Status__c != 'Approved for Signature') {
      throw new PartnerAgreementException(
        'Agreement must be approved for signature before release.'
      );
    }
    List<Partner_Agreement_Signatory__c> signatories = [
      SELECT Id, Name__c, Email__c, Role__c, Signing_Order__c
      FROM Partner_Agreement_Signatory__c
      WHERE Agreement__c = :agreementId
      WITH SYSTEM_MODE
      ORDER BY Signing_Order__c ASC
    ];
    if (signatories.isEmpty()) {
      throw new PartnerAgreementException(
        'At least one signatory is required.'
      );
    }

    PartnerSignatureProvider provider = PartnerSignatureProviderRouter.getProvider();
    String envelopeId = provider.sendEnvelope(agreement, signatories);
    String providerName = PartnerSignatureProviderRouter.getActiveProviderName();
    return releaseForSignature(agreementId, providerName, envelopeId);
  }

  /**
   * Releases an approved agreement to the e-signature provider, recording
   * the provider's envelope reference.
   *
   * @param agreementId Id of the Partner_Agreement__c to release.
   * @param provider Name of the e-signature provider.
   * @param envelopeId The provider's envelope identifier for this
   * agreement.
   * @return The updated Partner_Agreement__c record, now in Sent status.
   */
  public static Partner_Agreement__c releaseForSignature(
    Id agreementId,
    String provider,
    String envelopeId
  ) {
    Partner_Agreement__c agreement = [
      SELECT Id, Status__c
      FROM Partner_Agreement__c
      WHERE Id = :agreementId
      WITH SYSTEM_MODE
      LIMIT 1
      FOR UPDATE
    ];
    if (agreement.Status__c != 'Approved for Signature') {
      throw new PartnerAgreementException(
        'Agreement must be approved for signature before release.'
      );
    }
    Integer signatories = [
      SELECT COUNT()
      FROM Partner_Agreement_Signatory__c
      WHERE Agreement__c = :agreementId
      WITH SYSTEM_MODE
    ];
    if (
      signatories == 0 ||
      String.isBlank(provider) ||
      String.isBlank(envelopeId)
    ) {
      throw new PartnerAgreementException(
        'Provider envelope and at least one signatory are required.'
      );
    }
    agreement.Provider__c = provider;
    agreement.Provider_Envelope_Id__c = envelopeId;
    agreement.Status__c = 'Sent';
    Database.update(agreement, AccessLevel.SYSTEM_MODE);
    return agreement;
  }

  /**
   * Verifies and processes an inbound e-signature provider webhook event,
   * advancing the related agreement's status and recording the event.
   * Duplicate provider event ids are returned as-is without reprocessing,
   * and events outside the replay window or with an invalid HMAC
   * signature are rejected.
   *
   * @param envelopeId The provider's envelope identifier for the
   * agreement.
   * @param providerEventId The provider's unique identifier for this
   * event.
   * @param eventType The provider's event type (e.g. "sent", "viewed",
   * "completed").
   * @param occurredOn Timestamp the event occurred at the provider.
   * @param payload The raw event payload used for signature verification.
   * @param suppliedSignature The HMAC signature supplied with the event.
   * @param verificationSecret The shared secret used to verify the HMAC
   * signature.
   * @return The recorded Partner_Signature_Event__c record.
   */
  public static Partner_Signature_Event__c processProviderEvent(
    String envelopeId,
    String providerEventId,
    String eventType,
    Datetime occurredOn,
    String payload,
    String suppliedSignature,
    String verificationSecret
  ) {
    if (
      String.isBlank(providerEventId) ||
      String.isBlank(payload) ||
      occurredOn == null
    ) {
      throw new IllegalArgumentException(
        'Provider event identity, occurrence time and payload are required.'
      );
    }
    List<Partner_Signature_Event__c> duplicate = [
      SELECT Id, Processing_Status__c
      FROM Partner_Signature_Event__c
      WHERE Provider_Event_Id__c = :providerEventId
      WITH SYSTEM_MODE
      LIMIT 1
    ];
    if (!duplicate.isEmpty())
      return duplicate[0];
    if (
      occurredOn < System.now().addMinutes(-10) ||
      occurredOn > System.now().addMinutes(5)
    ) {
      throw new PartnerAgreementException(
        'Provider event is outside the replay window.'
      );
    }
    String expected = EncodingUtil.convertToHex(
      Crypto.generateMac(
        'HmacSHA256',
        Blob.valueOf(payload),
        Blob.valueOf(verificationSecret)
      )
    );
    if (
      String.isBlank(suppliedSignature) ||
      expected.toLowerCase() != suppliedSignature.toLowerCase()
    ) {
      throw new PartnerAgreementException(
        'Provider signature verification failed.'
      );
    }
    Partner_Agreement__c agreement = [
      SELECT Id, Status__c
      FROM Partner_Agreement__c
      WHERE Provider_Envelope_Id__c = :envelopeId
      WITH SYSTEM_MODE
      LIMIT 1
      FOR UPDATE
    ];
    String nextStatus = statusFor(eventType);
    if (rank(nextStatus) > rank(agreement.Status__c)) {
      agreement.Status__c = nextStatus;
      if (nextStatus == 'Executed')
        agreement.Executed_On__c = occurredOn;
      Database.update(agreement, AccessLevel.SYSTEM_MODE);
    }
    Partner_Signature_Event__c eventRecord = new Partner_Signature_Event__c(
      Agreement__c = agreement.Id,
      Provider_Event_Id__c = providerEventId,
      Event_Type__c = eventType,
      Provider_Occurred_On__c = occurredOn,
      Processed_On__c = System.now(),
      Signature_Verified__c = true,
      Payload_Hash__c = EncodingUtil.convertToHex(
        Crypto.generateDigest('SHA-256', Blob.valueOf(payload))
      ),
      Processing_Status__c = 'Processed'
    );
    Database.insert(eventRecord, AccessLevel.SYSTEM_MODE);
    return eventRecord;
  }

  /**
   * Marks an executed agreement as effective. Requires the
   * PartnerSync_Activate_Partner_Agreement custom permission.
   *
   * @param agreementId Id of the executed Partner_Agreement__c to
   * activate.
   * @param effectiveOn Date the agreement becomes effective.
   * @param expiresOn Date the agreement expires, if any.
   * @return The updated Partner_Agreement__c record.
   */
  public static Partner_Agreement__c markEffective(
    Id agreementId,
    Date effectiveOn,
    Date expiresOn
  ) {
    if (
      !FeatureManagement.checkPermission(
        'PartnerSync_Activate_Partner_Agreement'
      )
    ) {
      throw new PartnerAgreementException(
        'Agreement activation authority is required.'
      );
    }
    Partner_Agreement__c agreement = [
      SELECT Id, Status__c
      FROM Partner_Agreement__c
      WHERE Id = :agreementId
      WITH SYSTEM_MODE
      LIMIT 1
      FOR UPDATE
    ];
    if (agreement.Status__c != 'Executed')
      throw new PartnerAgreementException(
        'Only an executed agreement can become effective.'
      );
    agreement.Status__c = 'Effective';
    agreement.Effective_On__c = effectiveOn;
    agreement.Expires_On__c = expiresOn;
    Database.update(agreement, AccessLevel.SYSTEM_MODE);
    return agreement;
  }

  private static String statusFor(String eventType) {
    Map<String, String> statuses = new Map<String, String>{
      'sent' => 'Sent',
      'viewed' => 'Viewed',
      'partially_signed' => 'Partially Signed',
      'completed' => 'Executed'
    };
    if (!statuses.containsKey(eventType))
      throw new PartnerAgreementException('Unsupported provider event type.');
    return statuses.get(eventType);
  }

  private static Integer rank(String status) {
    List<String> ordered = new List<String>{
      'Draft',
      'Internal Review',
      'Negotiation',
      'Approved for Signature',
      'Sent',
      'Viewed',
      'Partially Signed',
      'Executed',
      'Effective'
    };
    Integer value = ordered.indexOf(status);
    return value < 0 ? 100 : value;
  }

  /**
   * Thrown when a partner agreement operation is attempted against a
   * record in an invalid state, or provider event verification fails.
   */
  public class PartnerAgreementException extends Exception {
  }
}
