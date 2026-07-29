/*
 * Selector layer for Account records that represent customers rather than
 * partners. Every query here is hard-scoped to Is_Partner__c = FALSE so
 * partner accounts can never be matched or returned as a "customer" during
 * lead conversion / deal registration flows.
 */
public with sharing class CustomerAccountSelector {
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

  public static Account selectCustomerAccountById(Id accountId) {
    SecurityUtil.assertReadable(Account.SObjectType);

    List<Account> rows = [
      SELECT Id, Name, Is_Partner__c
      FROM Account
      WHERE Id = :accountId AND Is_Partner__c = FALSE
      WITH USER_MODE
      LIMIT 1
    ];

    if (rows.isEmpty()) {
      throw new PartnerSyncHandledException(
        'Customer account not found or is not a valid customer account.'
      );
    }

    return rows[0];
  }
}
