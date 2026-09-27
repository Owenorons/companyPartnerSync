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

  @IsTest
  static void isAtRiskIsFalseBeforeTheWarningThreshold() {
    // Default policy: 72h window, 75% warning threshold -> at risk from
    // hour 54 onward. At hour 50, still well within the safe window.
    Datetime invitedOn = Datetime.newInstanceGMT(2026, 1, 1, 0, 0, 0);
    Datetime respondBy = invitedOn.addHours(72);
    Datetime asOf = invitedOn.addHours(50);

    Assert.isFalse(
      DealParticipantSlaService.isAtRisk(
        'Co-Sell Partner',
        invitedOn,
        respondBy,
        asOf
      )
    );
  }

  @IsTest
  static void isAtRiskIsTrueAfterTheWarningThresholdButBeforeTheDeadline() {
    Datetime invitedOn = Datetime.newInstanceGMT(2026, 1, 1, 0, 0, 0);
    Datetime respondBy = invitedOn.addHours(72);
    Datetime asOf = invitedOn.addHours(60);

    Assert.isTrue(
      DealParticipantSlaService.isAtRisk(
        'Co-Sell Partner',
        invitedOn,
        respondBy,
        asOf
      )
    );
  }

  @IsTest
  static void isAtRiskIsFalseOnceTheDeadlineHasPassed() {
    Datetime invitedOn = Datetime.newInstanceGMT(2026, 1, 1, 0, 0, 0);
    Datetime respondBy = invitedOn.addHours(72);
    Datetime asOf = invitedOn.addHours(80);

    // Past the deadline is "overdue", a distinct state the expiry batch
    // handles separately - not "at risk".
    Assert.isFalse(
      DealParticipantSlaService.isAtRisk(
        'Co-Sell Partner',
        invitedOn,
        respondBy,
        asOf
      )
    );
  }
}
