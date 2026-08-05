public with sharing class DealStateEngine {
  private static final Set<String> PARTNER_USER_TYPES = new Set<String>{
    'PowerPartner',
    'PowerCustomerSuccess',
    'CustomerSuccess',
    'CspLitePortal',
    'CSPLitePortal',
    'HighVolumePortal',
    'CustomerCommunity'
  };

  public static DealCommandContext evaluate(
    Deal_Registration__c deal,
    DealCommand command
  ) {
    String currentState = deal.Status__c;
    DealTransitionDefinition transition = DealStateTransitionSelector.selectTransition(
      command.aggregateType,
      command.lifecycleDimension,
      currentState,
      command.commandType
    );
    if (transition == null) {
      throw new DealLifecycleException(
        'The action "' +
          command.commandType +
          '" is not permitted while the aggregate is in "' +
          currentState +
          '".'
      );
    }
    if (transition.requiresReason == true && String.isBlank(command.reason)) {
      throw new DealLifecycleException('A reason is required for this action.');
    }

    Integer currentVersion = deal.Version_Number__c == null
      ? 0
      : Integer.valueOf(deal.Version_Number__c);
    if (
      transition.requiresVersion == true &&
      (command.expectedVersion == null ||
      command.expectedVersion != currentVersion)
    ) {
      throw new DealLifecycleException(
        'The deal was changed by another user. Refresh it before retrying this action.'
      );
    }
    if (deal.Lifecycle_Locked__c == true) {
      throw new DealLifecycleException(
        'The deal lifecycle is locked. ' + deal.Lifecycle_Lock_Reason__c
      );
    }
    if (
      String.isNotBlank(transition.requiredPermission) &&
      !FeatureManagement.checkPermission(transition.requiredPermission)
    ) {
      throw new DealLifecycleException(
        'You are not authorised to perform this action.'
      );
    }

    Boolean partnerActor = PARTNER_USER_TYPES.contains(UserInfo.getUserType());
    if (
      (partnerActor && transition.allowPartner != true) ||
      (!partnerActor && transition.allowInternal != true)
    ) {
      throw new DealLifecycleException(
        'This actor type cannot perform the requested action.'
      );
    }

    DealCommandContext context = new DealCommandContext();
    context.deal = deal;
    context.command = command;
    context.transition = transition;
    context.previousState = currentState;
    context.newState = transition.toState;
    context.previousVersion = currentVersion;
    context.newVersion = currentVersion + 1;
    context.eventType = transition.eventType;
    return context;
  }
}
