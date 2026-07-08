public with sharing class DealReviewService {
  public static List<DealReviewListDTO> getReviewQueue() {
    PartnerAccessService.assertInternalUser();

    List<DealReviewListDTO> results = new List<DealReviewListDTO>();

    for (Deal_Registration__c record : DealReviewSelector.selectReviewQueue()) {
      results.add(DealReviewDomain.toListDTO(record));
    }

    return results;
  }

  public static DealReviewDetailDTO getReviewDetail(Id dealId) {
    PartnerAccessService.assertInternalUser();

    Deal_Registration__c record = DealReviewSelector.selectForInternalReview(
      dealId
    );

    List<Deal_Registration__c> conflicts = DealReviewSelector.selectConflictsForDeal(
      record.Customer_Account__c,
      record.Id
    );

    return DealReviewDomain.toDetailDTO(record, conflicts);
  }

  public static void processDecision(DealReviewDecisionDTO request) {
    PartnerAccessService.assertInternalUser();

    DealReviewDomain.validateDecision(request);

    SecurityUtil.assertUpdateable(Deal_Registration__c.SObjectType);

    Deal_Registration__c record = DealReviewSelector.selectForInternalReview(
      request.dealId
    );

    if (request.decision == 'Approved') {
      assertCanFinalize(record);
      approve(record, request);
    } else if (request.decision == 'Rejected') {
      assertCanFinalize(record);
      reject(record, request);
    } else if (request.decision == 'Conflict Resolved') {
      resolveConflict(record, request);
    } else if (request.decision == 'Protection Extended') {
      extendProtection(record, request);
    }

    update SecurityUtil.stripForUpdate(new List<SObject>{ record });

    LoggingService.info(
      'DealReviewService',
      'Deal review decision processed. DealId=' + record.Id
    );
  }

  private static void assertCanFinalize(Deal_Registration__c record) {
    if (record.Status__c != 'Submitted' && record.Status__c != 'Under Review') {
      throw new PartnerSyncHandledException(
        'Only submitted or under review deals can be approved or rejected.'
      );
    }
  }

  private static void approve(
    Deal_Registration__c record,
    DealReviewDecisionDTO request
  ) {
    record.Status__c = 'Approved';
    // record.Conflict_Status__c =
    //     record.Conflict_Status__c == 'Potential Conflict'
    //         ? 'Conflict Review Required'
    //         : 'No Conflict';

    record.Protection_Start_Date__c = Date.today();
    record.Protection_End_Date__c = Date.today()
      .addDays(TenantConfigService.getDealExpiryDays());

    record.Approval_Notes__c = request.approvalNotes;
    record.Rejection_Reason__c = null;
    record.Decision_By__c = UserInfo.getUserId();
    record.Decision_On__c = System.now();
  }

  private static void reject(
    Deal_Registration__c record,
    DealReviewDecisionDTO request
  ) {
    record.Status__c = 'Rejected';
    record.Rejection_Reason__c = request.rejectionReason;
    record.Approval_Notes__c = request.approvalNotes;
    record.Decision_By__c = UserInfo.getUserId();
    record.Decision_On__c = System.now();
  }

  private static void resolveConflict(
    Deal_Registration__c record,
    DealReviewDecisionDTO request
  ) {
    record.Conflict_Status__c = 'Resolved';
    record.Conflict_Resolution_Notes__c = request.conflictResolutionNotes;

    record.Decision_By__c = UserInfo.getUserId();
    record.Decision_On__c = System.now();
  }

  private static void extendProtection(
    Deal_Registration__c record,
    DealReviewDecisionDTO request
  ) {
    Date baseDate = record.Protection_End_Date__c == null
      ? Date.today()
      : record.Protection_End_Date__c;

    record.Protection_End_Date__c = baseDate.addDays(
      request.protectionExtensionDays
    );

    record.Approval_Notes__c = request.approvalNotes;
    record.Decision_By__c = UserInfo.getUserId();
    record.Decision_On__c = System.now();
  }
}
