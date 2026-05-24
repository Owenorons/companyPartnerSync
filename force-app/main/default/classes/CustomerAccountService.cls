public with sharing class CustomerAccountService {
  public static CustomerAccountMatchDTO findOrCreateCustomerAccount(Lead lead) {
    if (lead == null) {
      throw new PartnerSyncHandledException('Lead is required.');
    }

    if (lead.Customer_Account__c != null) {
      Account existing = CustomerAccountSelector.selectCustomerAccountById(
        lead.Customer_Account__c
      );

      return toDTO(existing, false);
    }

    if (String.isBlank(lead.Company)) {
      throw new PartnerSyncHandledException(
        'Lead company is required to create a customer account.'
      );
    }

    String emailDomain = extractEmailDomain(lead.Email);

    List<Account> matches = CustomerAccountSelector.findCustomerAccounts(
      lead.Company,
      emailDomain
    );

    if (!matches.isEmpty()) {
      return toDTO(matches[0], false);
    }

    SecurityUtil.assertCreateable(Account.SObjectType);

    Account customer = new Account();
    customer.Name = lead.Company;
    customer.Is_Partner__c = false;

    List<SObject> sanitized = SecurityUtil.stripForCreate(
      new List<SObject>{ customer }
    );

    insert sanitized;

    return toDTO((Account) sanitized[0], true);
  }

  public static CustomerAccountMatchDTO findOrCreateCustomerAccount(
    String companyName,
    String email
  ) {
    if (String.isBlank(companyName)) {
      throw new PartnerSyncHandledException(
        'Company name is required to create a customer account.'
      );
    }

    String emailDomain = extractEmailDomain(email);

    List<Account> matches = CustomerAccountSelector.findCustomerAccounts(
      companyName,
      emailDomain
    );

    if (!matches.isEmpty()) {
      return toDTO(matches[0], false);
    }

    SecurityUtil.assertCreateable(Account.SObjectType);

    Account customer = new Account();
    customer.Name = companyName;
    customer.Is_Partner__c = false;

    List<SObject> sanitized = SecurityUtil.stripForCreate(
      new List<SObject>{ customer }
    );

    insert sanitized;

    return toDTO((Account) sanitized[0], true);
  }

  private static String extractEmailDomain(String email) {
    if (String.isBlank(email) || !email.contains('@')) {
      return null;
    }

    return email.substringAfter('@').toLowerCase();
  }

  private static CustomerAccountMatchDTO toDTO(
    Account account,
    Boolean created
  ) {
    CustomerAccountMatchDTO dto = new CustomerAccountMatchDTO();
    dto.accountId = account.Id;
    dto.accountName = account.Name;
    dto.created = created;
    return dto;
  }
}
