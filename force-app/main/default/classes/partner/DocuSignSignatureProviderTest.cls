/*
 * Test coverage for DocuSignSignatureProvider, covering the success,
 * non-2xx-status, and missing-template-key paths via
 * PartnerSignatureCalloutMock. Relies on the org's shipped
 * Signature_Provider_Config.DocuSign record for Named_Credential__c.
 */
@IsTest
private class DocuSignSignatureProviderTest {
  private static List<Partner_Agreement_Signatory__c> signatories() {
    return new List<Partner_Agreement_Signatory__c>{
      new Partner_Agreement_Signatory__c(
        Name__c = 'Partner Signer',
        Email__c = 'signer@example.test',
        Role__c = 'Partner',
        Signing_Order__c = 1
      )
    };
  }

  @IsTest
  static void sendEnvelopeReturnsEnvelopeIdOnSuccess() {
    Test.setMock(
      HttpCalloutMock.class,
      PartnerSignatureCalloutMock.success('envelope-123')
    );
    Partner_Agreement__c agreement = new Partner_Agreement__c(
      Template_Key__c = 'PROGRAMME-AU'
    );

    Test.startTest();
    String envelopeId = new DocuSignSignatureProvider()
      .sendEnvelope(agreement, signatories());
    Test.stopTest();

    Assert.areEqual('envelope-123', envelopeId);
  }

  @IsTest
  static void sendEnvelopeThrowsOnNonSuccessStatus() {
    Test.setMock(
      HttpCalloutMock.class,
      PartnerSignatureCalloutMock.failure(400, 'Bad template')
    );
    Partner_Agreement__c agreement = new Partner_Agreement__c(
      Template_Key__c = 'PROGRAMME-AU'
    );

    try {
      new DocuSignSignatureProvider().sendEnvelope(agreement, signatories());
      Assert.fail('Expected a provider failure.');
    } catch (PartnerAgreementService.PartnerAgreementException expected) {
      Assert.isTrue(expected.getMessage().contains('DocuSign request failed'));
    }
  }

  @IsTest
  static void sendEnvelopeThrowsWhenTemplateKeyMissing() {
    Partner_Agreement__c agreement = new Partner_Agreement__c();

    try {
      new DocuSignSignatureProvider().sendEnvelope(agreement, signatories());
      Assert.fail('Expected a template validation failure.');
    } catch (PartnerAgreementService.PartnerAgreementException expected) {
      Assert.isTrue(expected.getMessage().contains('template'));
    }
  }
}
