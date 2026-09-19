@IsTest
private class NotificationRecipientResolverTest {
  @IsTest
  static void groupsRecipientsByPartnerAccount() {
    Id firstAccountId = '001000000000001AAA';
    Id secondAccountId = '001000000000002AAA';
    List<User> recipients = new List<User>{
      relationshipUser('005000000000001AAA', firstAccountId),
      relationshipUser('005000000000002AAA', firstAccountId),
      relationshipUser('005000000000003AAA', secondAccountId)
    };

    Map<Id, List<User>> grouped = NotificationRecipientResolver.groupByPartnerAccount(
      recipients
    );

    Assert.areEqual(2, grouped.size());
    Assert.areEqual(2, grouped.get(firstAccountId).size());
    Assert.areEqual(1, grouped.get(secondAccountId).size());
  }

  @IsTest
  static void returnsEmptyResultsForMissingAccounts() {
    Assert.areEqual(
      0,
      NotificationRecipientResolver.resolveByPartnerAccount(null).size()
    );
    Assert.areEqual(
      0,
      NotificationRecipientResolver.resolveByPartnerAccount(new Set<Id>())
        .size()
    );
    Assert.areEqual(
      0,
      NotificationRecipientResolver.resolveByPartnerAccount(
          new Set<Id>{ '001000000000001AAA' }
        )
        .size()
    );
  }

  private static User relationshipUser(Id userId, Id accountId) {
    return (User) JSON.deserialize(
      '{"Id":"' +
        userId +
        '","ContactId":"003000000000001AAA","Contact":{"AccountId":"' +
        accountId +
        '"}}',
      User.class
    );
  }
}
