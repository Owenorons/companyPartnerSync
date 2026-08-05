public class DealLifecycleMutationGuard {
  public static void enforce(
    List<Deal_Registration__c> newRows,
    Map<Id, Deal_Registration__c> oldMap
  ) {
    if (
      DealLifecycleMutationContext.isControlledMutation() ||
      DealLifecycleMutationContext.isMigration()
    ) {
      return;
    }
    for (Deal_Registration__c row : newRows) {
      Deal_Registration__c oldRow = oldMap.get(row.Id);
      if (
        row.Lifecycle_Phase__c != oldRow.Lifecycle_Phase__c ||
        row.Version_Number__c != oldRow.Version_Number__c ||
        row.Last_Lifecycle_Event__c != oldRow.Last_Lifecycle_Event__c ||
        row.Lifecycle_Locked__c != oldRow.Lifecycle_Locked__c ||
        row.Lifecycle_Lock_Reason__c != oldRow.Lifecycle_Lock_Reason__c
      ) {
        row.addError(
          'Deal lifecycle control fields must be changed using an authorised deal command.'
        );
      }
    }
  }
}
