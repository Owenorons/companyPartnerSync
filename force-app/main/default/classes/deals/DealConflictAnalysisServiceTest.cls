@IsTest
private class DealConflictAnalysisServiceTest {
  @IsTest
  static void detectsCrossPartnerCandidateDebouncesAndPreservesHistory() {
    Account customer = new Account(Name = 'Shared Customer');
    Account partnerA = new Account(Name = 'Partner A');
    Account partnerB = new Account(Name = 'Partner B');
    insert new List<Account>{ customer, partnerA, partnerB };
    Deal_Registration__c existing = new Deal_Registration__c(
      Customer_Account__c = customer.Id,
      Partner_Account__c = partnerA.Id,
      Customer_Name__c = 'Shared Customer',
      Status__c = 'Submitted',
      Customer_Identity_Fingerprint__c = 'existing-fingerprint'
    );
    Deal_Registration__c candidate = new Deal_Registration__c(
      Customer_Account__c = customer.Id,
      Partner_Account__c = partnerB.Id,
      Customer_Name__c = 'Shared Customer',
      Status__c = 'Draft'
    );
    insert new List<Deal_Registration__c>{ existing, candidate };

    DealConflictContext context = contextFor(candidate, customer.Id);
    DealConflictDTO first = DealConflictAnalysisService.analyze(context);
    DealConflictDTO duplicate = DealConflictAnalysisService.analyze(context);
    Assert.isTrue(first.hasConflict);
    Assert.isTrue(duplicate.hasConflict);
    Assert.areEqual(
      1,
      [
        SELECT COUNT()
        FROM Deal_Conflict_Analysis_Run__c
        WHERE Deal__c = :candidate.Id
      ]
    );

    context.identity.fingerprint = 'changed-input';
    DealConflictAnalysisService.analyze(context);
    Assert.areEqual(
      2,
      [
        SELECT COUNT()
        FROM Deal_Conflict_Analysis_Run__c
        WHERE Deal__c = :candidate.Id
      ]
    );
    Assert.areEqual(
      1,
      [
        SELECT COUNT()
        FROM Deal_Conflict_Analysis_Run__c
        WHERE Deal__c = :candidate.Id AND Current__c = TRUE
      ]
    );
    Assert.isTrue(
      [
        SELECT COUNT()
        FROM Deal_Conflict__c
        WHERE Deal__c = :candidate.Id AND Current__c = FALSE
      ] > 0
    );
  }

  @IsTest
  static void approvalGuardAllowsTerminalFinding() {
    Deal_Registration__c deal = new Deal_Registration__c(
      Status__c = 'Submitted'
    );
    insert deal;
    insert new Deal_Conflict__c(
      Deal__c = deal.Id,
      Type__c = 'Existing Registration',
      Blocking__c = true,
      Current__c = true,
      Status__c = 'Resolved'
    );
    DealConflictApprovalGuard.assertNoBlockingConflicts(deal.Id);
  }

  private static DealConflictContext contextFor(
    Deal_Registration__c deal,
    Id customerId
  ) {
    DealConflictContext context = new DealConflictContext();
    context.deal = new Deal_Registration__c(
      Id = deal.Id,
      Customer_Account__c = customerId
    );
    context.identity = new DealCustomerIdentity();
    context.identity.fingerprint = 'input-fingerprint';
    context.validationFindings = new List<DealValidationFinding>();
    return context;
  }
}
