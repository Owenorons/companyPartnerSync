/**
 * Normalised, fingerprinted representation of a deal's customer identity,
 * used to detect potential registration conflicts between deals.
 */
public class DealCustomerIdentity {
  public String schemaVersion;
  public String normalizedLegalName;
  public String normalizedTradingName;
  public String normalizedDomain;
  public String normalizedPhone;
  public String normalizedAddress;
  public String country;
  public Id ultimateParentId;
  public String maskedRegistrationId;
  public String fingerprint;
}
