/*
 * Covers DealConflictWorkbenchService's read side: the same
 * PartnerSync_Resolve_Deal_Conflict permission that gates
 * DealConflictCommandService.execute() also gates the queue/detail reads -
 * there's no separate view-only access for this object, so a holder sees
 * exactly what they can act on and a non-holder sees nothing.
 */
@IsTest
private class DealConflictWorkbenchServiceTest {
  @IsTest
  static void holderSeesPendingQueueAndDetail() {
    Deal_Conflict__c conflict = createConflict('High', 'Open');
    authorize();

    List<DealConflictWorkbenchListDTO> queue = DealConflictWorkbenchService.getPendingConflicts();
    Assert.areEqual(1, queue.size());
    Assert.areEqual(conflict.Id, queue[0].conflictId);
    Assert.areEqual('Existing Registration', queue[0].type);
    Assert.areEqual('Open', queue[0].status);

    DealConflictWorkbenchDetailDTO detail = DealConflictWorkbenchService.getConflictDetail(
      conflict.Id
    );
    Assert.areEqual(conflict.Id, detail.conflictId);
    Assert.areEqual('High', detail.severity);
    Assert.isFalse(detail.canWaiveCritical);

    DealLifecyclePermissionService.clearTestPermissions();
  }

  @IsTest
  static void terminalConflictsAreExcludedFromTheQueue() {
    createConflict('High', 'Resolved');
    createConflict('High', 'Waived');
    createConflict('High', 'False Positive');
    createConflict('High', 'Superseded');
    Deal_Conflict__c openConflict = createConflict('High', 'Open');
    authorize();

    List<DealConflictWorkbenchListDTO> queue = DealConflictWorkbenchService.getPendingConflicts();
    Assert.areEqual(1, queue.size());
    Assert.areEqual(openConflict.Id, queue[0].conflictId);

    DealLifecyclePermissionService.clearTestPermissions();
  }

  @IsTest
  static void criticalWaiverHintReflectsHolderPermission() {
    Deal_Conflict__c conflict = createConflict('Critical', 'Confirmed');
    authorize();
    DealLifecyclePermissionService.setTestPermission(
      'PartnerSync_Waive_Critical_Conflict',
      true
    );

    DealConflictWorkbenchDetailDTO detail = DealConflictWorkbenchService.getConflictDetail(
      conflict.Id
    );
    Assert.isTrue(detail.canWaiveCritical);

    DealLifecyclePermissionService.clearTestPermissions();
  }

  @IsTest
  static void nonHolderIsBlockedFromTheWorkbench() {
    Deal_Conflict__c conflict = createConflict('High', 'Open');
    DealLifecyclePermissionService.setTestPermission(
      'PartnerSync_Resolve_Deal_Conflict',
      false
    );

    try {
      DealConflictWorkbenchService.getPendingConflicts();
      Assert.fail('Expected a non-holder to be blocked from the queue.');
    } catch (PartnerSyncHandledException expected) {
      Assert.isTrue(expected.getMessage().contains('permission'));
    }

    try {
      DealConflictWorkbenchService.getConflictDetail(conflict.Id);
      Assert.fail('Expected a non-holder to be blocked from the detail.');
    } catch (PartnerSyncHandledException expected) {
      Assert.isTrue(expected.getMessage().contains('permission'));
    }

    DealLifecyclePermissionService.clearTestPermissions();
  }

  private static Deal_Conflict__c createConflict(
    String severity,
    String status
  ) {
    Account customer = new Account(
      Name = 'Workbench Customer ' + severity + status
    );
    insert customer;
    Deal_Registration__c deal = new Deal_Registration__c(
      Status__c = 'Under Review',
      Customer_Account__c = customer.Id,
      Customer_Name__c = customer.Name,
      Customer_Identity_Fingerprint__c = 'fp-workbench-' + severity + status
    );
    insert deal;
    Deal_Conflict__c conflict = new Deal_Conflict__c(
      Deal__c = deal.Id,
      Type__c = 'Existing Registration',
      Severity__c = severity,
      Blocking__c = true,
      Current__c = true,
      Status__c = status,
      Version_Number__c = 0
    );
    insert conflict;
    return conflict;
  }

  private static void authorize() {
    DealLifecyclePermissionService.setTestPermission(
      'PartnerSync_Resolve_Deal_Conflict',
      true
    );
  }
}
