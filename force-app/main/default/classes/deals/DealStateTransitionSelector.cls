public without sharing class DealStateTransitionSelector {
  public static DealTransitionDefinition selectTransition(
    String aggregateType,
    String lifecycleDimension,
    String currentState,
    String action
  ) {
    List<Deal_State_Transition__mdt> rows = [
      SELECT
        Aggregate_Type__c,
        Lifecycle_Dimension__c,
        From_State__c,
        Action__c,
        To_State__c,
        Required_Permission__c,
        Handler_Class__c,
        Event_Type__c,
        Partner_Visible__c,
        Requires_Reason__c,
        Requires_Version__c,
        Allow_Partner__c,
        Allow_Internal__c
      FROM Deal_State_Transition__mdt
      WHERE
        Active__c = TRUE
        AND Aggregate_Type__c = :aggregateType
        AND Lifecycle_Dimension__c = :lifecycleDimension
        AND From_State__c = :currentState
        AND Action__c = :action
      WITH USER_MODE
      LIMIT 2
    ];

    if (rows.isEmpty()) {
      return null;
    }
    if (rows.size() > 1) {
      throw new DealLifecycleException(
        'Multiple active transitions are configured for this aggregate, state, and action.'
      );
    }

    Deal_State_Transition__mdt row = rows[0];
    DealTransitionDefinition result = new DealTransitionDefinition();
    result.aggregateType = row.Aggregate_Type__c;
    result.lifecycleDimension = row.Lifecycle_Dimension__c;
    result.fromState = row.From_State__c;
    result.action = row.Action__c;
    result.toState = row.To_State__c;
    result.requiredPermission = row.Required_Permission__c;
    result.handlerClass = row.Handler_Class__c;
    result.eventType = row.Event_Type__c;
    result.partnerVisible = row.Partner_Visible__c;
    result.requiresReason = row.Requires_Reason__c;
    result.requiresVersion = row.Requires_Version__c;
    result.allowPartner = row.Allow_Partner__c;
    result.allowInternal = row.Allow_Internal__c;
    return result;
  }
}
