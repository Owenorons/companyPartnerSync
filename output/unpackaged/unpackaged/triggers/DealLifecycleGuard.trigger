trigger DealLifecycleGuard on Deal_Registration__c(before update) {
  DealLifecycleMutationGuard.enforce(Trigger.new, Trigger.oldMap);
}
