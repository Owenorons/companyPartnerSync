/**
 * Executes Customer_Success_Activity__c commands: record. Deliberately
 * thin (Known Adaptation #2) - a structured log entry, not a state
 * machine.
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class CustomerSuccessActivityCommandService {
  /**
   * Records a customer success activity against an engagement.
   *
   * @param command engagementId + activityType + summary (required) + occurredOn.
   * @return The inserted activity.
   */
  public static Customer_Success_Activity__c record(
    CustomerSuccessActivityCommand command
  ) {
    PartnerAccessService.assertInternalUser();
    if (
      command.engagementId == null ||
      String.isBlank(command.activityType) ||
      String.isBlank(command.summary)
    ) {
      throw new PartnerSyncHandledException(
        'An engagement, activity type, and summary are required.'
      );
    }

    Customer_Success_Activity__c activity = new Customer_Success_Activity__c(
      Customer_Success_Engagement__c = command.engagementId,
      Activity_Type__c = command.activityType,
      Summary__c = command.summary,
      Occurred_On__c = command.occurredOn == null
        ? System.now()
        : command.occurredOn,
      Logged_By__c = UserInfo.getUserId()
    );
    Database.insert(activity, AccessLevel.SYSTEM_MODE);
    return activity;
  }
}
