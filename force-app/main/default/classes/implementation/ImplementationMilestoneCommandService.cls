/**
 * Executes Implementation_Milestone__c commands: create, start, complete,
 * block, waive; plus generateFromTemplate, called from
 * ImplementationCommandService.create() in the same transaction to
 * bulk-insert an implementation's initial milestone set from
 * Implementation_Milestone_Template__mdt.
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class ImplementationMilestoneCommandService {
  private static final String WAIVE_PERMISSION = 'PartnerSync_Waive_Implementation_Milestone';

  /**
   * Bulk-inserts milestones for a new implementation from whichever
   * Implementation_Milestone_Template__mdt rows match its
   * Implementation_Type__c, computing each Due_On__c from the
   * implementation's Planned_Start_Date__c + the template's Offset_Days__c.
   * Uses the CMDT platform cache (getAll()), not SOQL, so this stays
   * bulk-safe when called for many implementations in one batch chunk.
   *
   * @param implementation The newly-created implementation (already inserted).
   */
  public static void generateFromTemplate(
    Deal_Implementation__c implementation
  ) {
    Date startDate = implementation.Planned_Start_Date__c != null
      ? implementation.Planned_Start_Date__c
      : System.today();

    List<Implementation_Milestone__c> toInsert = new List<Implementation_Milestone__c>();
    for (
      Implementation_Milestone_Template__mdt template : Implementation_Milestone_Template__mdt.getAll()
        .values()
    ) {
      if (template.Active__c != true) {
        continue;
      }
      if (
        template.Implementation_Type__c != implementation.Implementation_Type__c
      ) {
        continue;
      }
      Integer offsetDays = template.Offset_Days__c == null
        ? 0
        : Integer.valueOf(template.Offset_Days__c);
      toInsert.add(
        new Implementation_Milestone__c(
          Implementation__c = implementation.Id,
          Milestone_Type__c = template.Milestone_Type__c,
          Name__c = template.Milestone_Type__c,
          Sequence__c = template.Sequence__c,
          Status__c = 'Not Started',
          Due_On__c = startDate.addDays(offsetDays),
          Required__c = template.Required__c == true,
          Blocking__c = template.Blocking__c == true,
          Evidence_Required__c = template.Evidence_Required__c == true,
          Customer_Acceptance_Required__c = template.Customer_Acceptance_Required__c ==
            true,
          Version_Number__c = 0
        )
      );
    }

    if (!toInsert.isEmpty()) {
      Database.insert(toInsert, AccessLevel.SYSTEM_MODE);
    }
  }

  /**
   * Creates a single ad-hoc milestone on an implementation (outside the
   * template-driven default set).
   *
   * @param command implementationId + milestone fields.
   * @return The inserted milestone.
   */
  public static Implementation_Milestone__c create(
    ImplementationMilestoneCommand command
  ) {
    PartnerAccessService.assertInternalUser();
    if (
      command.implementationId == null || String.isBlank(command.milestoneType)
    ) {
      throw new PartnerSyncHandledException(
        'An implementation and a milestone type are required.'
      );
    }
    Implementation_Milestone__c milestone = new Implementation_Milestone__c(
      Implementation__c = command.implementationId,
      Milestone_Type__c = command.milestoneType,
      Name__c = String.isBlank(command.name)
        ? command.milestoneType
        : command.name,
      Status__c = 'Not Started',
      Due_On__c = command.dueOn,
      Required__c = command.required == true,
      Blocking__c = command.blocking == true,
      Version_Number__c = 0
    );
    Database.insert(milestone, AccessLevel.SYSTEM_MODE);
    return milestone;
  }

  /**
   * Starts a Not Started milestone.
   *
   * @param command milestoneId + expected version.
   */
  public static void start(ImplementationMilestoneCommand command) {
    PartnerAccessService.assertInternalUser();
    Implementation_Milestone__c milestone = selectAndCheckVersion(command);
    if (milestone.Status__c != 'Not Started') {
      throw new PartnerSyncHandledException(
        'This milestone is not in a state that can be started.'
      );
    }
    milestone.Status__c = 'In Progress';
    milestone.Version_Number__c = versionAfter(milestone);
    Database.update(milestone, AccessLevel.SYSTEM_MODE);

    publish(
      milestone,
      'ImplementationMilestoneStarted',
      'A milestone started.'
    );
  }

  /**
   * Completes an In Progress milestone, checking Evidence_Required__c
   * against an Accepted Implementation_Evidence__c row first.
   *
   * @param command milestoneId + expected version.
   */
  public static void complete(ImplementationMilestoneCommand command) {
    PartnerAccessService.assertInternalUser();
    Implementation_Milestone__c milestone = selectAndCheckVersion(command);
    if (
      milestone.Status__c != 'In Progress' &&
      milestone.Status__c != 'Blocked'
    ) {
      throw new PartnerSyncHandledException(
        'This milestone is not in a state that can be completed.'
      );
    }
    if (milestone.Evidence_Required__c == true) {
      assertAcceptedEvidenceExists(milestone.Id);
    }

    milestone.Status__c = 'Completed';
    milestone.Actual_Date__c = System.today();
    milestone.Completion_Percentage__c = 100;
    milestone.Version_Number__c = versionAfter(milestone);
    Database.update(milestone, AccessLevel.SYSTEM_MODE);

    publish(
      milestone,
      'ImplementationMilestoneCompleted',
      'A milestone completed.'
    );
  }

  private static void assertAcceptedEvidenceExists(Id milestoneId) {
    if (
      [
        SELECT COUNT()
        FROM Implementation_Evidence__c
        WHERE Milestone__c = :milestoneId AND Status__c = 'Accepted'
        WITH SYSTEM_MODE
      ] == 0
    ) {
      throw new PartnerSyncHandledException(
        'This milestone requires accepted evidence before it can be completed.'
      );
    }
  }

  /**
   * Blocks an In Progress milestone, requiring a reason.
   *
   * @param command milestoneId + expected version + reason.
   */
  public static void block(ImplementationMilestoneCommand command) {
    PartnerAccessService.assertInternalUser();
    if (String.isBlank(command.reason)) {
      throw new PartnerSyncHandledException(
        'A reason is required to block a milestone.'
      );
    }
    Implementation_Milestone__c milestone = selectAndCheckVersion(command);
    milestone.Status__c = 'Blocked';
    milestone.Version_Number__c = versionAfter(milestone);
    Database.update(milestone, AccessLevel.SYSTEM_MODE);

    publish(
      milestone,
      'ImplementationMilestoneBlocked',
      'A milestone was blocked.'
    );
  }

  /**
   * Waives a milestone (restricted authority), requiring a reason.
   *
   * @param command milestoneId + expected version + reason.
   */
  public static void waive(ImplementationMilestoneCommand command) {
    PartnerAccessService.assertInternalUser();
    if (!DealLifecyclePermissionService.hasPermission(WAIVE_PERMISSION)) {
      throw new PartnerSyncHandledException(
        'Current user lacks authority to waive implementation milestones.'
      );
    }
    if (String.isBlank(command.reason)) {
      throw new PartnerSyncHandledException(
        'A reason is required to waive a milestone.'
      );
    }
    Implementation_Milestone__c milestone = selectAndCheckVersion(command);
    milestone.Status__c = 'Waived';
    milestone.Version_Number__c = versionAfter(milestone);
    Database.update(milestone, AccessLevel.SYSTEM_MODE);
  }

  private static Implementation_Milestone__c selectAndCheckVersion(
    ImplementationMilestoneCommand command
  ) {
    if (command.milestoneId == null) {
      throw new PartnerSyncHandledException(
        'A milestone is required for this command.'
      );
    }
    Implementation_Milestone__c milestone = ImplementationMilestoneSelector.selectForUpdate(
      command.milestoneId
    );
    Integer version = milestone.Version_Number__c == null
      ? 0
      : Integer.valueOf(milestone.Version_Number__c);
    if (command.expectedVersion == null || command.expectedVersion != version) {
      throw new PartnerSyncHandledException(
        'This milestone changed. Refresh before retrying.'
      );
    }
    return milestone;
  }

  private static Integer versionAfter(Implementation_Milestone__c milestone) {
    Integer current = milestone.Version_Number__c == null
      ? 0
      : Integer.valueOf(milestone.Version_Number__c);
    return current + 1;
  }

  private static void publish(
    Implementation_Milestone__c milestone,
    String eventType,
    String summary
  ) {
    PlatformEventPublisherService.publish(
      eventType,
      milestone.Implementation__c,
      'Deal_Implementation__c',
      null,
      summary,
      'Info'
    );
  }
}
