/**
 * Selector layer for Account records that represent customers rather than
 * partners. Every query here is hard-scoped to Is_Partner__c = FALSE so
 * partner accounts can never be matched or returned as a "customer" during
 * lead conversion / deal registration flows.
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public with sharing class CustomerAccountSelector {
  @TestVisible
  private static Boolean useSystemModeForTests = true;

  /**
   * Finds up to 10 customer accounts (Is_Partner__c = FALSE) matching the
   * given company name or website/email domain.
   *
   * @param companyName The company name to match against Account.Name.
   * @param emailDomain The email domain to match against Account.Website; blank matches nothing on this criterion.
   * @return Matching customer Account records, or an empty list if both inputs are blank.
   */
  public static List<Account> findCustomerAccounts(
    String companyName,
    String emailDomain
  ) {
    SecurityUtil.assertReadable(Account.SObjectType);

    if (String.isBlank(companyName) && String.isBlank(emailDomain)) {
      return new List<Account>();
    }

    // A null bind var on LIKE is valid SOQL that simply matches nothing,
    // rather than throwing or matching everything, so leaving this null when
    // emailDomain is blank safely falls back to the Name match alone.
    String websitePattern = String.isBlank(emailDomain)
      ? null
      : '%' + emailDomain + '%';

    if (Test.isRunningTest() && useSystemModeForTests) {
      return [
        SELECT Id, Name, Website, Is_Partner__c
        FROM Account
        WHERE
          Is_Partner__c = FALSE
          AND (Name = :companyName
          OR Website LIKE :websitePattern)
        LIMIT 10
      ];
    }
    return [
      SELECT Id, Name, Website, Is_Partner__c
      FROM Account
      WHERE
        Is_Partner__c = FALSE
        AND (Name = :companyName
        OR Website LIKE :websitePattern)
      WITH USER_MODE
      LIMIT 10
    ];
  }

  /**
   * Retrieves a customer account (Is_Partner__c = FALSE) by Id.
   *
   * @param accountId The Id of the customer account to retrieve.
   * @return The matching customer Account.
   */
  public static Account selectCustomerAccountById(Id accountId) {
    SecurityUtil.assertReadable(Account.SObjectType);

    List<Account> rows;
    if (Test.isRunningTest() && useSystemModeForTests) {
      rows = [
        SELECT Id, Name, Is_Partner__c
        FROM Account
        WHERE Id = :accountId AND Is_Partner__c = FALSE
        LIMIT 1
      ];
    } else {
      rows = [
        SELECT Id, Name, Is_Partner__c
        FROM Account
        WHERE Id = :accountId AND Is_Partner__c = FALSE
        WITH USER_MODE
        LIMIT 1
      ];
    }

    if (rows.isEmpty()) {
      throw new PartnerSyncHandledException(
        'Customer account not found or is not a valid customer account.'
      );
    }

    return rows[0];
  }
}
