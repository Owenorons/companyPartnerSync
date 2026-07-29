/*
 * Covers EmailNotificationService.sendNotification(): confirms it doesn't
 * throw for a valid address and is a silent no-op for a blank one.
 */
@IsTest
private class EmailNotificationServiceTest {
  @IsTest
  static void sendNotificationSendsEmailForValidAddress() {
    Boolean threw = false;

    Test.startTest();
    try {
      EmailNotificationService.sendNotification(
        'partner@example.com',
        'Deal approved',
        'Your deal registration was approved.'
      );
    } catch (Exception ex) {
      threw = true;
    }
    Test.stopTest();

    System.assertEquals(
      false,
      threw,
      'Sending to a valid address should not raise an exception.'
    );
  }

  @IsTest
  static void sendNotificationIsNoOpForBlankAddress() {
    Boolean threw = false;

    try {
      EmailNotificationService.sendNotification('', 'Subject', 'Body');
    } catch (Exception ex) {
      threw = true;
    }

    System.assertEquals(
      false,
      threw,
      'A blank recipient address should short-circuit without error.'
    );
  }
}
