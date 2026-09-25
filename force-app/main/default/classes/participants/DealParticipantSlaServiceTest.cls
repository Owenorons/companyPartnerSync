@IsTest
private class DealParticipantSlaServiceTest {
  @IsTest
  static void fallsBackToTheDefaultPolicyWhenNoTypeSpecificOneExists() {
    Datetime invitedOn = Datetime.newInstanceGMT(2026, 1, 1, 9, 0, 0);

    Datetime respondBy = DealParticipantSlaService.computeRespondBy(
      'Co-Sell Partner',
      invitedOn
    );

    Assert.areEqual(invitedOn.addHours(72), respondBy);
  }
}
