/** Resolves active Experience Cloud users for partner-account events. */
public without sharing class NotificationRecipientResolver {
  @TestVisible
  private static Map<Id, List<User>> testRecipientsByAccount = new Map<Id, List<User>>();

  /**
   * Resolves the active Experience Cloud users associated (via their
   * Contact's Account) with each of the given partner account ids, so they
   * can receive event notifications. In test context, also merges in any
   * recipients seeded via testRecipientsByAccount.
   *
   * @param partnerAccountIds The partner account ids to resolve recipients for.
   * @return A map of partner account id to the list of active users linked to that account.
   */
  public static Map<Id, List<User>> resolveByPartnerAccount(
    Set<Id> partnerAccountIds
  ) {
    Map<Id, List<User>> recipientsByAccount = new Map<Id, List<User>>();
    if (partnerAccountIds == null || partnerAccountIds.isEmpty())
      return recipientsByAccount;

    recipientsByAccount = groupByPartnerAccount(
      [
        SELECT Id, ContactId, Contact.AccountId
        FROM User
        WHERE IsActive = TRUE AND Contact.AccountId IN :partnerAccountIds
        WITH SYSTEM_MODE
      ]
    );
    if (Test.isRunningTest()) {
      for (Id accountId : testRecipientsByAccount.keySet()) {
        if (!partnerAccountIds.contains(accountId))
          continue;
        if (!recipientsByAccount.containsKey(accountId))
          recipientsByAccount.put(accountId, new List<User>());
        recipientsByAccount.get(accountId)
          .addAll(testRecipientsByAccount.get(accountId));
      }
    }
    return recipientsByAccount;
  }

  @TestVisible
  private static Map<Id, List<User>> groupByPartnerAccount(
    List<User> recipients
  ) {
    Map<Id, List<User>> recipientsByAccount = new Map<Id, List<User>>();
    for (User recipient : recipients) {
      Id accountId = recipient.Contact.AccountId;
      if (!recipientsByAccount.containsKey(accountId))
        recipientsByAccount.put(accountId, new List<User>());
      recipientsByAccount.get(accountId).add(recipient);
    }
    return recipientsByAccount;
  }
}
