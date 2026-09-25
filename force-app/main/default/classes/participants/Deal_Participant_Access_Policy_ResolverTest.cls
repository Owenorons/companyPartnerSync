@IsTest
private class Deal_Participant_Access_Policy_ResolverTest {
  @IsTest
  static void appliesExactTypeAndRoleMatch() {
    Deal_Participant__c participant = new Deal_Participant__c(
      Participant_Type__c = 'Co-Sell Partner',
      Participant_Role__c = 'Co-Sell Contributor'
    );

    Deal_Participant_Access_Policy_Resolver.applyAccessSnapshot(participant);

    Assert.areEqual('Collaborator', participant.Access_Level__c);
    Assert.isTrue(participant.Can_Collaborate__c);
    Assert.isFalse(participant.Can_View_Commercials__c);
  }

  @IsTest
  static void observerRoleReceivesNoCommercialAccess() {
    Deal_Participant__c participant = new Deal_Participant__c(
      Participant_Type__c = 'Co-Sell Partner',
      Participant_Role__c = 'Observer'
    );

    Deal_Participant_Access_Policy_Resolver.applyAccessSnapshot(participant);

    Assert.areEqual('Summary', participant.Access_Level__c);
    Assert.isFalse(participant.Can_View_Commercials__c);
    Assert.isFalse(participant.Can_Edit_Deal__c);
    Assert.isFalse(participant.Can_Collaborate__c);
  }

  @IsTest
  static void fallsBackToTypeOnlyPolicyWhenNoRoleMatchExists() {
    Deal_Participant__c participant = new Deal_Participant__c(
      Participant_Type__c = 'Internal Sales',
      Participant_Role__c = 'Sales Lead'
    );

    Deal_Participant_Access_Policy_Resolver.applyAccessSnapshot(participant);

    Assert.areEqual('Internal Only', participant.Access_Level__c);
    Assert.isTrue(participant.Can_View_Commercials__c);
  }

  @IsTest
  static void explicitlyRequestedAccessLevelIsNotOverridden() {
    Deal_Participant__c participant = new Deal_Participant__c(
      Participant_Type__c = 'Co-Sell Partner',
      Participant_Role__c = 'Co-Sell Contributor',
      Access_Level__c = 'Full Partner'
    );

    Deal_Participant_Access_Policy_Resolver.applyAccessSnapshot(participant);

    Assert.areEqual('Full Partner', participant.Access_Level__c);
    // Capability flags still resolve from policy even when the level is kept.
    Assert.isTrue(participant.Can_Collaborate__c);
  }

  @IsTest
  static void noMatchingPolicyLeavesTheParticipantUnchanged() {
    Deal_Participant__c participant = new Deal_Participant__c(
      Participant_Type__c = 'Executive Sponsor',
      Participant_Role__c = 'Executive Sponsor'
    );

    Deal_Participant_Access_Policy_Resolver.applyAccessSnapshot(participant);

    Assert.isNull(participant.Access_Level__c);
  }
}
