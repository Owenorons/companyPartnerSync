public with sharing class CustomerAccountSelector {
  public static List<Account> findCustomerAccounts(
    String companyName,
    String emailDomain
  ) {
    SecurityUtil.assertReadable(Account.SObjectType);

    if (String.isBlank(companyName) && String.isBlank(emailDomain)) {
      return new List<Account>();
    }

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
      LIMIT 10
    ];
  }

  public static Account selectCustomerAccountById(Id accountId) {
    SecurityUtil.assertReadable(Account.SObjectType);

    List<Account> rows = [
      SELECT Id, Name, Is_Partner__c
      FROM Account
      WHERE Id = :accountId AND Is_Partner__c = FALSE
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
