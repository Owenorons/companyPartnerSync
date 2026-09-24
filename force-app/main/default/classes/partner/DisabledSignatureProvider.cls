/**
 * Null-object implementation of PartnerSignatureProvider: returned by
 * PartnerSignatureProviderRouter whenever no e-signature provider is
 * configured active. Unlike AIProvider's "never throw" convention,
 * PartnerSignatureProvider.sendEnvelope has no result DTO to carry a
 * failure in, so this always throws a clear, callable error instead of
 * silently fabricating an envelope id.
 */
public with sharing class DisabledSignatureProvider implements PartnerSignatureProvider {
  /**
   * Always throws; never performs a callout.
   *
   * @param agreement The Partner_Agreement__c record to be signed (ignored).
   * @param signatories The signatories who must sign the agreement (ignored).
   * @return Never returns.
   */
  public String sendEnvelope(
    Partner_Agreement__c agreement,
    List<Partner_Agreement_Signatory__c> signatories
  ) {
    throw new PartnerAgreementService.PartnerAgreementException(
      'No e-signature provider is configured active.'
    );
  }
}
