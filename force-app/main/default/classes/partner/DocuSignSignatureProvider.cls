/**
 * PartnerSignatureProvider implementation adapting the DocuSign eSignature
 * REST API's template-based envelope creation
 * (POST /v2.1/accounts/{accountId}/envelopes with a templateId and
 * templateRoles). Partner_Agreement__c.Template_Key__c supplies the
 * DocuSign template id; each Partner_Agreement_Signatory__c becomes one
 * templateRole, ordered by Signing_Order__c.
 */
public with sharing class DocuSignSignatureProvider implements PartnerSignatureProvider {
  /**
   * Sends the agreement's template for signature to its signatories via
   * DocuSign, returning the resulting envelope id. Throws
   * PartnerAgreementService.PartnerAgreementException (rather than a raw
   * callout exception) whenever the provider is unconfigured or the
   * callout does not succeed, since this interface has no result DTO to
   * carry a failure in.
   *
   * @param agreement The Partner_Agreement__c record to be signed.
   * @param signatories The signatories who must sign the agreement.
   * @return The DocuSign envelope id for the sent envelope.
   */
  public String sendEnvelope(
    Partner_Agreement__c agreement,
    List<Partner_Agreement_Signatory__c> signatories
  ) {
    Signature_Provider_Config__mdt config = Signature_Provider_Config__mdt.getInstance(
      'DocuSign'
    );

    if (config == null || String.isBlank(config.Named_Credential__c)) {
      throw new PartnerAgreementService.PartnerAgreementException(
        'DocuSign provider is not configured.'
      );
    }
    if (String.isBlank(agreement.Template_Key__c)) {
      throw new PartnerAgreementService.PartnerAgreementException(
        'Agreement has no DocuSign template configured.'
      );
    }

    try {
      HttpRequest req = new HttpRequest();
      req.setEndpoint(
        'callout:' +
          config.Named_Credential__c +
          '/v2.1/accounts/' +
          (String.isBlank(config.Account_Id__c) ? '' : config.Account_Id__c) +
          '/envelopes'
      );
      req.setMethod('POST');
      req.setHeader('Content-Type', 'application/json');
      req.setTimeout(timeoutMillis(config));
      req.setBody(JSON.serialize(buildPayload(agreement, signatories)));

      HttpResponse res = new Http().send(req);
      return parseEnvelopeId(res);
    } catch (PartnerAgreementService.PartnerAgreementException ex) {
      throw ex;
    } catch (Exception ex) {
      throw new PartnerAgreementService.PartnerAgreementException(
        'DocuSign envelope request failed: ' + ex.getMessage()
      );
    }
  }

  private Map<String, Object> buildPayload(
    Partner_Agreement__c agreement,
    List<Partner_Agreement_Signatory__c> signatories
  ) {
    List<Object> templateRoles = new List<Object>();
    for (Partner_Agreement_Signatory__c signatory : signatories) {
      templateRoles.add(
        new Map<String, Object>{
          'roleName' => signatory.Role__c,
          'name' => signatory.Name__c,
          'email' => signatory.Email__c,
          'routingOrder' => String.valueOf(signatory.Signing_Order__c)
        }
      );
    }

    return new Map<String, Object>{
      'templateId' => agreement.Template_Key__c,
      'status' => 'sent',
      'templateRoles' => templateRoles
    };
  }

  private String parseEnvelopeId(HttpResponse res) {
    if (res.getStatusCode() < 200 || res.getStatusCode() >= 300) {
      throw new PartnerAgreementService.PartnerAgreementException(
        'DocuSign request failed with status ' +
          res.getStatusCode() +
          ': ' +
          res.getBody()
      );
    }

    Map<String, Object> body = (Map<String, Object>) JSON.deserializeUntyped(
      res.getBody()
    );
    String envelopeId = (String) body.get('envelopeId');
    if (String.isBlank(envelopeId)) {
      throw new PartnerAgreementService.PartnerAgreementException(
        'DocuSign response did not include an envelope id.'
      );
    }
    return envelopeId;
  }

  private Integer timeoutMillis(Signature_Provider_Config__mdt config) {
    Integer seconds = config.Timeout_Seconds__c == null
      ? 30
      : Integer.valueOf(config.Timeout_Seconds__c);
    return seconds * 1000;
  }
}
