for (Partner_Onboarding__c onboarding : [
  SELECT Id FROM Partner_Onboarding__c WHERE Status__c = 'Onboarding'
]) {
  PartnerReadinessLifecycleService.evaluate(onboarding.Id);
}
