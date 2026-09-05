public without sharing class DealStateTransitionSelector {
  public static DealTransitionDefinition selectTransition(
    String aggregateType,
    String lifecycleDimension,
    String currentState,
    String action
  ) {
    String objectApiName = resolveTransitionObjectApiName();
    String transitionSuffix = 'Deal_State_Transition__mdt';
    String prefix = objectApiName.substring(
      0,
      objectApiName.length() - transitionSuffix.length()
    );
    String query =
      'SELECT ' +
      fieldList(prefix) +
      ' FROM ' +
      objectApiName +
      ' WHERE ' +
      prefix +
      'Active__c = TRUE AND ' +
      prefix +
      'Aggregate_Type__c = :aggregateType AND ' +
      prefix +
      'Lifecycle_Dimension__c = :lifecycleDimension AND ' +
      prefix +
      'From_State__c = :currentState AND ' +
      prefix +
      'Action__c = :action LIMIT 2';

    List<SObject> rows = Database.queryWithBinds(
      query,
      new Map<String, Object>{
        'aggregateType' => aggregateType,
        'lifecycleDimension' => lifecycleDimension,
        'currentState' => currentState,
        'action' => action
      },
      AccessLevel.SYSTEM_MODE
    );
    if (rows.isEmpty()) {
      return null;
    }
    if (rows.size() > 1) {
      throw new DealLifecycleException(
        'Multiple active transitions are configured for this aggregate, state, and action.'
      );
    }

    SObject row = rows[0];
    DealTransitionDefinition result = new DealTransitionDefinition();
    result.aggregateType = (String) row.get(prefix + 'Aggregate_Type__c');
    result.lifecycleDimension = (String) row.get(
      prefix + 'Lifecycle_Dimension__c'
    );
    result.fromState = (String) row.get(prefix + 'From_State__c');
    result.action = (String) row.get(prefix + 'Action__c');
    result.toState = (String) row.get(prefix + 'To_State__c');
    result.requiredPermission = (String) row.get(
      prefix + 'Required_Permission__c'
    );
    result.handlerClass = (String) row.get(prefix + 'Handler_Class__c');
    result.eventType = (String) row.get(prefix + 'Event_Type__c');
    result.partnerVisible = (Boolean) row.get(prefix + 'Partner_Visible__c');
    result.requiresReason = (Boolean) row.get(prefix + 'Requires_Reason__c');
    result.requiresVersion = (Boolean) row.get(prefix + 'Requires_Version__c');
    result.allowPartner = (Boolean) row.get(prefix + 'Allow_Partner__c');
    result.allowInternal = (Boolean) row.get(prefix + 'Allow_Internal__c');
    return result;
  }

  private static String resolveTransitionObjectApiName() {
    for (String apiName : Schema.getGlobalDescribe().keySet()) {
      if (apiName.toLowerCase().endsWith('deal_state_transition__mdt')) {
        return apiName;
      }
    }
    throw new DealLifecycleException(
      'Deal state transition metadata is not installed.'
    );
  }

  private static String fieldList(String prefix) {
    List<String> names = new List<String>{
      'Aggregate_Type__c',
      'Lifecycle_Dimension__c',
      'From_State__c',
      'Action__c',
      'To_State__c',
      'Required_Permission__c',
      'Handler_Class__c',
      'Event_Type__c',
      'Partner_Visible__c',
      'Requires_Reason__c',
      'Requires_Version__c',
      'Allow_Partner__c',
      'Allow_Internal__c'
    };
    for (Integer index = 0; index < names.size(); index++) {
      names[index] = prefix + names[index];
    }
    return String.join(names, ', ');
  }
}
