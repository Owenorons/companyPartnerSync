public with sharing class PartnerApplicationApprovalDomain {
  public static void validateDecision(PartnerApprovalRequestDTO request) {
    if (request == null || request.applicationId == null) {
      throw new PartnerSyncHandledException(
        'Partner approval request is invalid.'
      );
    }

    if (request.decision != 'Approved' && request.decision != 'Rejected') {
      throw new PartnerSyncHandledException(
        'Unsupported partner approval decision.'
      );
    }

    if (
      request.decision == 'Rejected' && String.isBlank(request.rejectionReason)
    ) {
      throw new PartnerSyncHandledException('Rejection reason is required.');
    }
  }

  public static Account buildPartnerAccount(
    Partner_Application__c application
  ) {
    Account account = new Account();
    account.Name = application.Company_Name__c;
    account.Is_Partner__c = true;
    account.Partner_Status__c = 'Active';
    account.Partner_Tier__c = application.Requested_Tier__c;
    account.Partner_Type__c = application.Partner_Type__c;
    account.Partner_Region__c = application.Region__c;
    account.Program_Start_Date__c = Date.today();
    return account;
  }

  public static Contact buildPrimaryPartnerContact(
    Partner_Application__c application,
    Id accountId
  ) {
    Contact contact = new Contact();
    contact.AccountId = accountId;
    contact.LastName = buildContactLastName(
      application.Submitted_By_Contact_Name__c
    );
    contact.Email = application.Submitted_By_Email__c;
    contact.Phone = application.Phone__c;
    contact.Is_Partner_User__c = true;
    contact.Portal_Role__c = 'Partner Admin';
    return contact;
  }

  private static String buildContactLastName(String submittedName) {
    if (String.isBlank(submittedName)) {
      return 'Primary Contact';
    }

    return submittedName.trim();
  }
}
