/**
 * Executes Implementation_Issue__c commands: raise, escalate, resolve,
 * acceptRisk (restricted). raise/resolve trigger
 * ImplementationHealthService.recompute() so the implementation's health
 * reflects the current open-issue roster immediately.
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class ImplementationIssueCommandService {
  /**
   * Raises a new issue on an implementation. Internal users may always
   * raise; external/partner users need PartnerSync_Raise_Implementation_Issue.
   *
   * @param command implementationId + issue fields.
   * @return The inserted issue record.
   */
  public static Implementation_Issue__c raise(
    ImplementationIssueCommand command
  ) {
    if (
      !PartnerAccessService.isInternalUser() &&
      !DealLifecyclePermissionService.hasPermission(
        'PartnerSync_Raise_Implementation_Issue'
      )
    ) {
      throw new PartnerSyncHandledException(
        'Current user lacks authority to raise implementation issues.'
      );
    }
    if (
      command.implementationId == null ||
      String.isBlank(command.issueType) ||
      String.isBlank(command.title)
    ) {
      throw new PartnerSyncHandledException(
        'An implementation, issue type, and title are required.'
      );
    }

    Implementation_Issue__c issue = new Implementation_Issue__c(
      Implementation__c = command.implementationId,
      Milestone__c = command.milestoneId,
      Issue_Type__c = command.issueType,
      Severity__c = String.isBlank(command.severity)
        ? 'Medium'
        : command.severity,
      Status__c = 'Open',
      Title__c = command.title,
      Description__c = command.description,
      Raised_On__c = System.now(),
      Raised_By__c = UserInfo.getUserId(),
      Owner__c = command.ownerId,
      Partner_Account__c = command.partnerAccountId,
      Customer_Impact__c = command.customerImpact == true,
      Commercial_Impact__c = command.commercialImpact == true
    );
    Database.insert(issue, AccessLevel.SYSTEM_MODE);

    PlatformEventPublisherService.publish(
      'ImplementationIssueRaised',
      command.implementationId,
      'Deal_Implementation__c',
      command.partnerAccountId,
      'An implementation issue was raised.',
      issue.Severity__c == 'Critical' ? 'Error' : 'Warning'
    );

    ImplementationHealthService.recompute(command.implementationId);

    return issue;
  }

  /**
   * Escalates an open issue, incrementing its escalation level.
   *
   * @param command issueId + reason.
   */
  public static void escalate(ImplementationIssueCommand command) {
    PartnerAccessService.assertInternalUser();
    if (
      !DealLifecyclePermissionService.hasPermission(
        'PartnerSync_Escalate_Implementation'
      )
    ) {
      throw new PartnerSyncHandledException(
        'Current user lacks authority to escalate implementation issues.'
      );
    }
    Implementation_Issue__c issue = requireOpenIssue(command);

    issue.Status__c = 'Escalated';
    issue.Escalation_Level__c =
      (issue.Escalation_Level__c == null
        ? 0
        : Integer.valueOf(issue.Escalation_Level__c)) + 1;
    Database.update(issue, AccessLevel.SYSTEM_MODE);

    PlatformEventPublisherService.publish(
      'ImplementationIssueEscalated',
      issue.Implementation__c,
      'Deal_Implementation__c',
      issue.Partner_Account__c,
      'An implementation issue was escalated.',
      'Warning'
    );
  }

  /**
   * Resolves an open issue, requiring a resolution description.
   *
   * @param command issueId + resolution.
   */
  public static void resolve(ImplementationIssueCommand command) {
    PartnerAccessService.assertInternalUser();
    if (String.isBlank(command.resolution)) {
      throw new PartnerSyncHandledException(
        'A resolution description is required to resolve an issue.'
      );
    }
    Implementation_Issue__c issue = requireOpenIssue(command);

    issue.Status__c = 'Resolved';
    issue.Resolution__c = command.resolution;
    issue.Resolved_On__c = System.now();
    Database.update(issue, AccessLevel.SYSTEM_MODE);

    PlatformEventPublisherService.publish(
      'ImplementationIssueResolved',
      issue.Implementation__c,
      'Deal_Implementation__c',
      issue.Partner_Account__c,
      'An implementation issue was resolved.',
      'Info'
    );

    ImplementationHealthService.recompute(issue.Implementation__c);
  }

  /**
   * Accepts the risk of an open issue rather than resolving it (restricted
   * authority).
   *
   * @param command issueId + reason.
   */
  public static void acceptRisk(ImplementationIssueCommand command) {
    PartnerAccessService.assertInternalUser();
    if (
      !DealLifecyclePermissionService.hasPermission(
        'PartnerSync_Accept_Implementation_Risk'
      )
    ) {
      throw new PartnerSyncHandledException(
        'Current user lacks authority to accept implementation risk.'
      );
    }
    if (String.isBlank(command.reason)) {
      throw new PartnerSyncHandledException(
        'A reason is required to accept implementation risk.'
      );
    }
    Implementation_Issue__c issue = requireOpenIssue(command);

    issue.Status__c = 'Accepted Risk';
    issue.Resolution__c = command.reason;
    issue.Resolved_On__c = System.now();
    Database.update(issue, AccessLevel.SYSTEM_MODE);

    ImplementationHealthService.recompute(issue.Implementation__c);
  }

  private static Implementation_Issue__c requireOpenIssue(
    ImplementationIssueCommand command
  ) {
    if (command.issueId == null) {
      throw new PartnerSyncHandledException(
        'An issue is required for this command.'
      );
    }
    Implementation_Issue__c issue = ImplementationIssueSelector.selectForUpdate(
      command.issueId
    );
    if (
      issue.Status__c == 'Resolved' ||
      issue.Status__c == 'Accepted Risk' ||
      issue.Status__c == 'Closed'
    ) {
      throw new PartnerSyncHandledException(
        'This issue has already been closed out.'
      );
    }
    return issue;
  }
}
