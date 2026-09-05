public without sharing class PartnerOperationalAlertActionService {
  public static Partner_Operational_Alert__c resolve(Id alertId) {
    assertAuthority();
    Partner_Operational_Alert__c alert = selectForUpdate(alertId);
    if (alert.Status__c == 'Resolved')
      throw new AlertActionException(
        'The operational alert is already resolved.'
      );
    alert.Status__c = 'Resolved';
    alert.Resolved_By__c = UserInfo.getUserId();
    alert.Resolved_On__c = System.now();
    Database.update(alert, AccessLevel.SYSTEM_MODE);
    return alert;
  }

  public static Partner_Operational_Alert__c reopen(Id alertId) {
    assertAuthority();
    Partner_Operational_Alert__c alert = selectForUpdate(alertId);
    if (alert.Status__c != 'Resolved')
      throw new AlertActionException(
        'Only resolved operational alerts can be reopened.'
      );
    alert.Status__c = 'Open';
    alert.Reopened_By__c = UserInfo.getUserId();
    alert.Reopened_On__c = System.now();
    alert.Notification_Status__c = 'Pending';
    alert.Notified_On__c = null;
    Database.update(alert, AccessLevel.SYSTEM_MODE);
    return alert;
  }

  private static Partner_Operational_Alert__c selectForUpdate(Id alertId) {
    if (alertId == null)
      throw new AlertActionException('Operational alert Id is required.');
    return [
      SELECT Id, Status__c, Notification_Status__c, Notified_On__c
      FROM Partner_Operational_Alert__c
      WHERE Id = :alertId
      WITH SYSTEM_MODE
      LIMIT 1
      FOR UPDATE
    ];
  }

  private static void assertAuthority() {
    if (
      !FeatureManagement.checkPermission(
        'PartnerSync_Manage_Operational_Alerts'
      )
    )
      throw new AlertActionException(
        'Operational alert management authority is required.'
      );
  }

  public class AlertActionException extends Exception {
  }
}
