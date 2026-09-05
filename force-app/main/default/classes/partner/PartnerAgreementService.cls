/** Contracting aggregate and verified provider-event processing. */
public without sharing class PartnerAgreementService {
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

  public class PartnerAgreementException extends Exception {
  }
}
