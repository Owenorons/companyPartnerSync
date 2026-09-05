public with sharing class DealCustomerIdentityService {
  private static final String SCHEMA_VERSION = 'v1';

  public static DealCustomerIdentity derive(Id accountId) {
    DealCustomerIdentity identity = new DealCustomerIdentity();
    identity.schemaVersion = SCHEMA_VERSION;
    if (accountId == null) {
      identity.fingerprint = fingerprint(identity);
      return identity;
    }
    Account account = [
      SELECT
        Name,
        Tradestyle,
        Website,
        Phone,
        BillingStreet,
        BillingCity,
        BillingState,
        BillingPostalCode,
        BillingCountry,
        AccountNumber,
        DunsNumber,
        ParentId,
        Parent.ParentId
      FROM Account
      WHERE Id = :accountId
      WITH USER_MODE
    ];
    identity.normalizedLegalName = normalizeName(
      account.Name,
      account.BillingCountry
    );
    identity.normalizedTradingName = normalizeName(
      account.Tradestyle,
      account.BillingCountry
    );
    identity.normalizedDomain = normalizeDomain(account.Website);
    identity.normalizedPhone = digits(account.Phone);
    identity.normalizedAddress = joinNormalized(
      new List<String>{
        account.BillingStreet,
        account.BillingCity,
        account.BillingState,
        account.BillingPostalCode,
        account.BillingCountry
      }
    );
    identity.country = normalizeToken(account.BillingCountry);
    identity.ultimateParentId = account.Parent == null
      ? account.Id
      : (account.Parent.ParentId == null
          ? account.ParentId
          : account.Parent.ParentId);
    identity.maskedRegistrationId = mask(
      String.isBlank(account.AccountNumber)
        ? account.DunsNumber
        : account.AccountNumber
    );
    identity.fingerprint = fingerprint(identity);
    return identity;
  }

  @TestVisible
  private static String normalizeName(String value, String country) {
    String normalized = normalizeToken(value);
    if (String.isBlank(normalized))
      return normalized;
    Set<String> suffixes = new Set<String>{
      'ltd',
      'limited',
      'inc',
      'incorporated',
      'corp',
      'corporation',
      'llc'
    };
    if (normalizeToken(country) == 'australia') {
      suffixes.addAll(new Set<String>{ 'pty', 'proprietary' });
    }
    List<String> tokens = normalized.split(' ');
    while (!tokens.isEmpty() && suffixes.contains(tokens[tokens.size() - 1])) {
      tokens.remove(tokens.size() - 1);
    }
    return String.join(tokens, ' ');
  }

  private static String normalizeDomain(String value) {
    if (String.isBlank(value))
      return null;
    String domain = value.trim().toLowerCase();
    domain = domain.replaceFirst('^https?://', '').replaceFirst('^www\\.', '');
    Integer slash = domain.indexOf('/');
    return slash < 0 ? domain : domain.substring(0, slash);
  }

  private static String digits(String value) {
    return String.isBlank(value) ? null : value.replaceAll('[^0-9]', '');
  }

  private static String joinNormalized(List<String> values) {
    List<String> tokens = new List<String>();
    for (String value : values)
      tokens.add(orMissing(normalizeToken(value)));
    return String.join(tokens, '|');
  }

  private static String normalizeToken(String value) {
    if (String.isBlank(value))
      return null;
    return value.toLowerCase()
      .replaceAll('[^a-z0-9]+', ' ')
      .trim()
      .replaceAll(' +', ' ');
  }

  private static String mask(String value) {
    if (String.isBlank(value))
      return null;
    String clean = value.replaceAll('[^A-Za-z0-9]', '');
    return clean.length() <= 4 ? '****' : '****' + clean.right(4);
  }

  private static String fingerprint(DealCustomerIdentity identity) {
    String canonical = String.join(
      new List<String>{
        SCHEMA_VERSION,
        orMissing(identity.normalizedLegalName),
        orMissing(identity.normalizedTradingName),
        orMissing(identity.normalizedDomain),
        orMissing(identity.normalizedPhone),
        orMissing(identity.normalizedAddress),
        orMissing(identity.country),
        orMissing(String.valueOf(identity.ultimateParentId))
      },
      '|'
    );
    return EncodingUtil.convertToHex(
      Crypto.generateDigest('SHA-256', Blob.valueOf(canonical))
    );
  }

  private static String orMissing(String value) {
    return String.isBlank(value) ? '<missing>' : value;
  }
}
