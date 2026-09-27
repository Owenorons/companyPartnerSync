/*
 * Covers ImplementationSlaService.isHandoffOverdueForAcceptance() against
 * the seeded Default record's 48-hour threshold.
 */
@IsTest
private class ImplementationSlaServiceTest {
  @IsTest
  static void withinTheAcceptanceWindowIsNotOverdue() {
    Datetime submittedOn = Datetime.now().addHours(-10);
    Assert.isFalse(
      ImplementationSlaService.isHandoffOverdueForAcceptance(
        'Initial Implementation',
        submittedOn,
        Datetime.now()
      )
    );
  }

  @IsTest
  static void pastTheAcceptanceWindowIsOverdue() {
    Datetime submittedOn = Datetime.now().addHours(-50);
    Assert.isTrue(
      ImplementationSlaService.isHandoffOverdueForAcceptance(
        'Initial Implementation',
        submittedOn,
        Datetime.now()
      )
    );
  }

  @IsTest
  static void aNullSubmissionTimeIsNeverOverdue() {
    Assert.isFalse(
      ImplementationSlaService.isHandoffOverdueForAcceptance(
        'Initial Implementation',
        null,
        Datetime.now()
      )
    );
  }
}
