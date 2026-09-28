/**
 * Executes Customer_Success_Milestone__c commands: create, complete, skip.
 * Deliberately lightweight (Known Adaptation #2) - a checkpoint row, not a
 * generic task engine with automation beyond simple insert/query.
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class CustomerSuccessMilestoneCommandService {
  /**
   * Creates a Not Started milestone on an engagement.
   *
   * @param command engagementId + milestoneType + targetOn.
   * @return The inserted milestone.
   */
  public static Customer_Success_Milestone__c create(
    CustomerSuccessMilestoneCommand command
  ) {
    PartnerAccessService.assertInternalUser();
    if (command.engagementId == null || String.isBlank(command.milestoneType)) {
      throw new PartnerSyncHandledException(
        'An engagement and milestone type are required.'
      );
    }

    Customer_Success_Milestone__c milestone = new Customer_Success_Milestone__c(
      Customer_Success_Engagement__c = command.engagementId,
      Milestone_Type__c = command.milestoneType,
      Status__c = 'Not Started',
      Target_On__c = command.targetOn,
      Notes__c = command.notes
    );
    Database.insert(milestone, AccessLevel.SYSTEM_MODE);
    return milestone;
  }

  /**
   * Completes a milestone.
   *
   * @param command milestoneId.
   * @return The updated milestone.
   */
  public static Customer_Success_Milestone__c complete(
    CustomerSuccessMilestoneCommand command
  ) {
    PartnerAccessService.assertInternalUser();
    Customer_Success_Milestone__c milestone = requireMilestone(command);

    milestone.Status__c = 'Completed';
    milestone.Completed_On__c = System.today();
    Database.update(milestone, AccessLevel.SYSTEM_MODE);
    return milestone;
  }

  /**
   * Skips a milestone, recording why.
   *
   * @param command milestoneId + notes (the skip reason).
   * @return The updated milestone.
   */
  public static Customer_Success_Milestone__c skip(
    CustomerSuccessMilestoneCommand command
  ) {
    PartnerAccessService.assertInternalUser();
    if (String.isBlank(command.notes)) {
      throw new PartnerSyncHandledException(
        'A reason is required to skip a milestone.'
      );
    }
    Customer_Success_Milestone__c milestone = requireMilestone(command);

    milestone.Status__c = 'Skipped';
    milestone.Notes__c = command.notes;
    Database.update(milestone, AccessLevel.SYSTEM_MODE);
    return milestone;
  }

  private static Customer_Success_Milestone__c requireMilestone(
    CustomerSuccessMilestoneCommand command
  ) {
    if (command.milestoneId == null) {
      throw new PartnerSyncHandledException(
        'A milestone is required for this command.'
      );
    }
    return CustomerSuccessMilestoneSelector.selectForUpdate(
      command.milestoneId
    );
  }
}
