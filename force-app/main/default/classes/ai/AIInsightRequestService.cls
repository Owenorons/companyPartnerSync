/**
 * Lightweight request queue standing in for partner self-service AI
 * generation: AIInsightGeneratorService.validate() hard-gates generation
 * to internal users only (not just a permission, an isInternalUser()
 * check), so a partner can't trigger the real pipeline directly. Instead,
 * a partner's request lands here for an internal user (holding the same
 * PartnerSync_Generate_AI_Insights permission generation itself requires)
 * to action through the existing governance console.
 */
public without sharing class AIInsightRequestService {
  /**
   * Submits a request on behalf of the running partner user for their own
   * account.
   *
   * @param insightType DeveloperName of the requested AI_Feature_Config__mdt.
   * @param notes The partner's free-text context for the request.
   * @return The created AI_Insight_Request__c record.
   */
  public static AI_Insight_Request__c submitRequest(
    String insightType,
    String notes
  ) {
    if (String.isBlank(insightType)) {
      throw new PartnerSyncHandledException('Insight type is required.');
    }
    AI_Feature_Config__mdt feature = AI_Feature_Config__mdt.getInstance(
      insightType
    );
    if (feature == null || !feature.Enabled__c) {
      throw new PartnerSyncHandledException(
        'The requested AI feature is not enabled.'
      );
    }

    Id partnerAccountId = PartnerAccessService.getCurrentPartnerAccountId();
    Contact contact = PartnerAccessService.getCurrentPartnerContact();

    AI_Insight_Request__c request = new AI_Insight_Request__c(
      Partner_Account__c = partnerAccountId,
      Requested_By__c = contact.Id,
      Insight_Type__c = insightType,
      Notes__c = notes,
      Status__c = 'New',
      Requested_On__c = System.now()
    );
    Database.insert(request, AccessLevel.SYSTEM_MODE);
    return request;
  }

  /**
   * Lists the running partner's own AI insight requests.
   *
   * @return The caller's own AI_Insight_Request__c records.
   */
  public static List<AI_Insight_Request__c> getMyRequests() {
    Id partnerAccountId = PartnerAccessService.getCurrentPartnerAccountId();
    return AIInsightSelector.selectRequestsForPartner(partnerAccountId);
  }

  /**
   * Lists requests awaiting internal action. Requires the same
   * generate-insights permission actioning a request leads to.
   *
   * @return New AI_Insight_Request__c records.
   */
  public static List<AI_Insight_Request__c> getPendingRequests() {
    PartnerPermissionService.assertCanGenerateAIInsights();
    return AIInsightSelector.selectPendingRequests();
  }

  /**
   * Marks a request Actioned by the running internal user, returning it
   * so the caller can pre-fill the generate form. Actioning only records
   * that the request was picked up — the reviewer still triggers
   * generation themselves via the existing enqueueInsight flow.
   *
   * @param requestId Id of the AI_Insight_Request__c to action.
   * @return The updated request record.
   */
  public static AI_Insight_Request__c actionRequest(Id requestId) {
    PartnerPermissionService.assertCanGenerateAIInsights();
    AI_Insight_Request__c request = AIInsightSelector.selectRequestById(
      requestId
    );
    if (request.Status__c != 'New') {
      throw new PartnerSyncHandledException(
        'Only a new request can be actioned.'
      );
    }
    request.Status__c = 'Actioned';
    request.Actioned_By__c = UserInfo.getUserId();
    request.Actioned_On__c = System.now();
    Database.update(request, AccessLevel.SYSTEM_MODE);
    return request;
  }

  /**
   * Marks a request Dismissed by the running internal user.
   *
   * @param requestId Id of the AI_Insight_Request__c to dismiss.
   * @return The updated request record.
   */
  public static AI_Insight_Request__c dismissRequest(Id requestId) {
    PartnerPermissionService.assertCanGenerateAIInsights();
    AI_Insight_Request__c request = AIInsightSelector.selectRequestById(
      requestId
    );
    if (request.Status__c != 'New') {
      throw new PartnerSyncHandledException(
        'Only a new request can be dismissed.'
      );
    }
    request.Status__c = 'Dismissed';
    request.Actioned_By__c = UserInfo.getUserId();
    request.Actioned_On__c = System.now();
    Database.update(request, AccessLevel.SYSTEM_MODE);
    return request;
  }
}
