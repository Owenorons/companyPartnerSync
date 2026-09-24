@IsTest
private class PartnerAgreementServiceTest {
  private static Partner_Onboarding__c onboarding(Boolean approved) {
    Partner_Application__c application = new Partner_Application__c(
      Name = 'Contract Test Partner',
      Company_Name__c = 'Contract Test Partner',
      Business_Email__c = 'contract@example.test',
      Application_Status__c = 'Approved',
      Country__c = 'Australia',
      Partner_Type__c = 'Reseller',
      Requested_Tier__c = 'Gold'
    );
    insert application;
    Partner_Onboarding__c record = new Partner_Onboarding__c(
      Application__c = application.Id,
      Onboarding_Key__c = String.valueOf(application.Id),
      Status__c = 'Onboarding',
      Current_Stage__c = 'Contracting',
      Activation_Gate_Status__c = 'Blocked',
      Version_Number__c = 1
    );
    insert record;
    insert new Partner_Approval_Plan__c(
      Onboarding__c = record.Id,
      Plan_Key__c = record.Id + ':TEST:1',
      Version_Number__c = 1,
      Current__c = true,
      Status__c = approved ? 'Approved for Contracting' : 'Pending',
      Generated_On__c = System.now()
    );
    return record;
  }

  private static Partner_Agreement__c releasedAgreement() {
    Partner_Onboarding__c record = onboarding(true);
    Partner_Agreement__c agreement = PartnerAgreementService.createAgreement(
      record.Id,
      'Programme Agreement',
      record.Id + ':PROGRAMME:1',
      'PROGRAMME-AU',
      3
    );
    PartnerAgreementService.addSignatory(
      agreement.Id,
      agreement.Id + ':PARTNER',
      'Partner Signer',
      'signer@example.test',
      'Partner',
      1
    );
    agreement.Status__c = 'Approved for Signature';
    update agreement;
    return PartnerAgreementService.releaseForSignature(
      agreement.Id,
      'DocuSign',
      'envelope-001'
    );
  }

  private static Partner_Agreement__c approvedForSignatureAgreement() {
    Partner_Onboarding__c record = onboarding(true);
    Partner_Agreement__c agreement = PartnerAgreementService.createAgreement(
      record.Id,
      'Programme Agreement',
      record.Id + ':PROGRAMME:SEND',
      'PROGRAMME-AU',
      3
    );
    PartnerAgreementService.addSignatory(
      agreement.Id,
      agreement.Id + ':PARTNER',
      'Partner Signer',
      'signer@example.test',
      'Partner',
      1
    );
    agreement.Status__c = 'Approved for Signature';
    update agreement;
    return agreement;
  }

  @IsTest
  static void sendForSignatureRoutesThroughActiveProviderAndReleases() {
    Partner_Agreement__c agreement = approvedForSignatureAgreement();
    Test.setMock(
      HttpCalloutMock.class,
      PartnerSignatureCalloutMock.success('envelope-777')
    );
    try {
      PartnerSignatureProviderRouter.providerConfigForTest = new Signature_Provider_Config__mdt(
        Active__c = true,
        Provider_Name__c = 'DocuSign',
        Provider_Type__c = 'DocuSign'
      );
      Test.startTest();
      Partner_Agreement__c sent = PartnerAgreementService.sendForSignature(
        agreement.Id
      );
      Test.stopTest();
      System.assertEquals('Sent', sent.Status__c);
      System.assertEquals('DocuSign', sent.Provider__c);
      System.assertEquals('envelope-777', sent.Provider_Envelope_Id__c);
    } finally {
      PartnerSignatureProviderRouter.providerConfigForTest = null;
    }
  }

  @IsTest
  static void sendForSignatureThrowsWhenNoProviderConfigured() {
    Partner_Agreement__c agreement = approvedForSignatureAgreement();
    try {
      PartnerAgreementService.sendForSignature(agreement.Id);
      System.assert(false, 'Expected a disabled-provider failure.');
    } catch (PartnerAgreementService.PartnerAgreementException expected) {
      System.assert(expected.getMessage().contains('not configured'));
    }
  }

  @IsTest
  static void sendForSignatureRequiresApprovedStatus() {
    Partner_Onboarding__c record = onboarding(true);
    Partner_Agreement__c agreement = PartnerAgreementService.createAgreement(
      record.Id,
      'NDA',
      record.Id + ':NDA:SEND',
      'NDA-AU',
      1
    );
    try {
      PartnerAgreementService.sendForSignature(agreement.Id);
      System.assert(false, 'Expected an approval-status failure.');
    } catch (PartnerAgreementService.PartnerAgreementException expected) {
      System.assert(expected.getMessage().contains('approved for signature'));
    }
  }

  @IsTest
  static void sendForSignatureRequiresAtLeastOneSignatory() {
    Partner_Onboarding__c record = onboarding(true);
    Partner_Agreement__c agreement = PartnerAgreementService.createAgreement(
      record.Id,
      'NDA',
      record.Id + ':NDA:NOSIGNER',
      'NDA-AU',
      1
    );
    agreement.Status__c = 'Approved for Signature';
    update agreement;
    try {
      PartnerAgreementService.sendForSignature(agreement.Id);
      System.assert(false, 'Expected a signatory requirement failure.');
    } catch (PartnerAgreementService.PartnerAgreementException expected) {
      System.assert(expected.getMessage().contains('signatory'));
    }
  }

  @IsTest
  static void contractingRequiresFinalApprovalAndIsIdempotent() {
    Partner_Onboarding__c blocked = onboarding(false);
    try {
      PartnerAgreementService.createAgreement(
        blocked.Id,
        'NDA',
        'blocked-agreement',
        'NDA-AU',
        1
      );
      System.assert(false, 'Expected approval gate.');
    } catch (PartnerAgreementService.PartnerAgreementException expected) {
      System.assert(expected.getMessage().contains('approval'));
    }
    Partner_Onboarding__c approved = onboarding(true);
    Partner_Agreement__c first = PartnerAgreementService.createAgreement(
      approved.Id,
      'NDA',
      'approved-agreement',
      'NDA-AU',
      2
    );
    Partner_Agreement__c second = PartnerAgreementService.createAgreement(
      approved.Id,
      'NDA',
      'approved-agreement',
      'NDA-AU',
      2
    );
    System.assertEquals(first.Id, second.Id);
  }

  @IsTest
  static void verifiedCompletedEventIsIdempotentAndExecutedNotEffective() {
    Partner_Agreement__c agreement = releasedAgreement();
    String payload = '{"event":"completed"}';
    String secret = 'test-secret';
    String signature = EncodingUtil.convertToHex(
      Crypto.generateMac(
        'HmacSHA256',
        Blob.valueOf(payload),
        Blob.valueOf(secret)
      )
    );
    Datetime occurred = System.now();
    Test.startTest();
    Partner_Signature_Event__c first = PartnerAgreementService.processProviderEvent(
      'envelope-001',
      'provider-event-001',
      'completed',
      occurred,
      payload,
      signature,
      secret
    );
    Partner_Signature_Event__c second = PartnerAgreementService.processProviderEvent(
      'envelope-001',
      'provider-event-001',
      'completed',
      occurred,
      payload,
      signature,
      secret
    );
    Test.stopTest();
    System.assertEquals(first.Id, second.Id);
    agreement = [
      SELECT Status__c, Executed_On__c, Effective_On__c
      FROM Partner_Agreement__c
      WHERE Id = :agreement.Id
    ];
    System.assertEquals('Executed', agreement.Status__c);
    System.assertNotEquals(null, agreement.Executed_On__c);
    System.assertEquals(null, agreement.Effective_On__c);
  }

  @IsTest
  static void rejectsInvalidSignatureAndReplay() {
    releasedAgreement();
    try {
      PartnerAgreementService.processProviderEvent(
        'envelope-001',
        'bad-signature',
        'viewed',
        System.now(),
        '{}',
        'invalid',
        'secret'
      );
      System.assert(false, 'Expected signature rejection.');
    } catch (PartnerAgreementService.PartnerAgreementException expected) {
      System.assert(expected.getMessage().contains('signature'));
    }
    try {
      PartnerAgreementService.processProviderEvent(
        'envelope-001',
        'replayed',
        'viewed',
        System.now().addHours(-1),
        '{}',
        'invalid',
        'secret'
      );
      System.assert(false, 'Expected replay rejection.');
    } catch (PartnerAgreementService.PartnerAgreementException expected) {
      System.assert(expected.getMessage().contains('replay'));
    }
  }

  @IsTest
  static void addSignatoryRejectedOnceAgreementIsSent() {
    Partner_Agreement__c agreement = releasedAgreement();
    try {
      PartnerAgreementService.addSignatory(
        agreement.Id,
        agreement.Id + ':LATE',
        'Late Signer',
        'late@example.test',
        'Partner',
        2
      );
      System.assert(false, 'Expected sent-agreement guard.');
    } catch (PartnerAgreementService.PartnerAgreementException expected) {
      System.assert(expected.getMessage().contains('sent for signature'));
    }
  }

  @IsTest
  static void effectiveStateRequiresSeparateAuthority() {
    Partner_Agreement__c agreement = releasedAgreement();
    User unprivilegedUser = TestUserFactory.createInternalUser();
    System.runAs(unprivilegedUser) {
      try {
        PartnerAgreementService.markEffective(
          agreement.Id,
          Date.today(),
          Date.today().addYears(1)
        );
        System.assert(false, 'Expected activation authority.');
      } catch (PartnerAgreementService.PartnerAgreementException expected) {
        System.assert(expected.getMessage().contains('authority'));
      }
    }
  }
}
