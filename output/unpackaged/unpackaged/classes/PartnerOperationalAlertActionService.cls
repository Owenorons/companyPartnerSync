/**
 * Interactive resolve/reopen actions for a Partner_Operational_Alert__c
 * record, gated behind the PartnerSync_Manage_Operational_Alerts custom
 * permission.
 */
public without sharing class PartnerOperationalAlertActionService {
  /**
   * Marks an open operational alert as resolved by the running user.
   *
   * @param alertId Id of the Partner_Operational_Alert__c record to resolve.
   * @return The updated, resolved alert record.
   */
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

  /**
   * Reopens a previously resolved operational alert and resets it back to
   * pending notification.
   *
   * @param alertId Id of the Partner_Operational_Alert__c record to reopen.
   * @return The updated, reopened alert record.
   */
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

  /**
   * Thrown when an operational alert resolve/reopen action is attempted
   * without authority, against a missing alert, or against an alert whose
   * current status doesn't allow the requested action.
   */
  public class AlertActionException extends Exception {
  }
}
