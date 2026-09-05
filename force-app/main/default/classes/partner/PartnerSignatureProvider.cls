/** Provider-neutral boundary implemented by an approved e-signature adapter. */
public interface PartnerSignatureProvider {
  String sendEnvelope(
    Partner_Agreement__c agreement,
    List<Partner_Agreement_Signatory__c> signatories
  );
}
