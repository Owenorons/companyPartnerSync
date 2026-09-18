/** Provider-neutral boundary implemented by an approved e-signature adapter. */
public interface PartnerSignatureProvider {
  /**
   * Sends a partner agreement out for signature to its signatories.
   *
   * @param agreement The Partner_Agreement__c record to be signed.
   * @param signatories The signatories who must sign the agreement.
   * @return An identifier for the resulting signature envelope, as issued by the provider.
   */
  String sendEnvelope(
    Partner_Agreement__c agreement,
    List<Partner_Agreement_Signatory__c> signatories
  );
}
