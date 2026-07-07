public with sharing class PartnerAccessService {
  public static Id getCurrentPartnerAccountId() {
    User currentUser = [
      SELECT Id, UserType, ContactId, Contact.AccountId
      FROM User
      WHERE Id = :UserInfo.getUserId()
      LIMIT 1
    ];

    if (
      currentUser.ContactId == null ||
      currentUser.Contact.AccountId == null
    ) {
      throw new PartnerSyncHandledException(
        'The current user is not linked to a partner account.'
      );
    }

    return currentUser.Contact.AccountId;
  }

  public static Contact getCurrentPartnerContact() {
    User currentUser = [
      SELECT Id, ContactId
      FROM User
      WHERE Id = :UserInfo.getUserId()
      LIMIT 1
    ];

    if (currentUser.ContactId == null) {
      throw new PartnerSyncHandledException(
        'The current user is not linked to a partner contact.'
      );
    }

    List<Contact> contacts = [
      SELECT Id, AccountId, Name, Email, Phone
      FROM Contact
      WHERE Id = :currentUser.ContactId
      LIMIT 1
    ];

    if (contacts.isEmpty()) {
      throw new PartnerSyncHandledException(
        'The current partner contact could not be found.'
      );
    }

    return contacts[0];
  }

  public static Boolean isInternalUser() {
    User currentUser = [
      SELECT Id, UserType
      FROM User
      WHERE Id = :UserInfo.getUserId()
      LIMIT 1
    ];

    return currentUser.UserType == 'Standard';
  }

  public static Boolean isExternalUser() {
    return !isInternalUser();
  }

  public static void assertInternalUser() {
    if (!isInternalUser()) {
      throw new PartnerSyncHandledException(
        'Only internal users can perform this action.'
      );
    }
  }

  public static void assertCurrentUserCanAccessPartnerAccount(
    Id partnerAccountId
  ) {
    if (partnerAccountId == null) {
      throw new PartnerSyncHandledException('Partner account is required.');
    }

    if (isInternalUser()) {
      return;
    }

    Id currentPartnerAccountId = getCurrentPartnerAccountId();

    if (currentPartnerAccountId != partnerAccountId) {
      throw new PartnerSyncHandledException('Record not accessible.');
    }
  }
}
