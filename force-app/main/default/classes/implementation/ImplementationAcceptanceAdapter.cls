/**
 * Adapter boundary for recording customer acceptance (doc §40.30) - a
 * future e-sign provider, uploaded signed document, or API confirmation
 * mode is a clean addition behind this interface without changing
 * ImplementationAcceptanceCommandService. Only SalesforceHostedAcceptanceAdapter
 * exists today (Sprint 40 Known Adaptation #8) - no e-signature provider
 * integration exists anywhere in this codebase to adapt to yet.
 */
public interface ImplementationAcceptanceAdapter {
  /**
   * Applies the acceptance decision fields to the given (already
   * FOR-UPDATE-locked) acceptance record. Does not perform the DML -
   * the caller (ImplementationAcceptanceCommandService) owns that, so
   * every adapter mode goes through the same version-check/update path.
   *
   * @param acceptance The locked Implementation_Acceptance__c record to update in place.
   * @param acceptedByName Display name of whoever accepted.
   * @param acceptedByEmail Email of whoever accepted, if known.
   */
  void applyAcceptance(
    Implementation_Acceptance__c acceptance,
    String acceptedByName,
    String acceptedByEmail
  );
}
