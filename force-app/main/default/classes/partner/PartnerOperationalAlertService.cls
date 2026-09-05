/** Durable, deduplicated operational diagnostics for onboarding v2. */
public without sharing class PartnerOperationalAlertService implements Schedulable {
  @TestVisible
  private static Boolean testManageAuthority = false;

  public static List<Partner_Operational_Alert__c> scan() {
    Map<String, Partner_Operational_Alert__c> candidates = new Map<String, Partner_Operational_Alert__c>();
    Datetime nowValue = System.now();
    Datetime recent = nowValue.addHours(-2);
    for (Partner_Provisioning_Attempt__c attempt : [
      SELECT Id, Outcome__c, Error_Detail__c
      FROM Partner_Provisioning_Attempt__c
      WHERE Status__c = 'Failed' AND LastModifiedDate >= :recent
      WITH SYSTEM_MODE
      LIMIT 200
    ])
      add(
        candidates,
        'PROVISIONING:' + attempt.Id,
        'Provisioning Failure',
        'High',
        attempt.Id,
        String.isBlank(attempt.Error_Detail__c)
          ? attempt.Outcome__c
          : attempt.Error_Detail__c,
        nowValue
      );

    for (Partner_Signature_Event__c eventRecord : [
      SELECT Id, Event_Type__c
      FROM Partner_Signature_Event__c
      WHERE Processing_Status__c = 'Failed' AND LastModifiedDate >= :recent
      WITH SYSTEM_MODE
      LIMIT 200
    ])
      add(
        candidates,
        'SIGNATURE:' + eventRecord.Id,
        'Signature Event Failure',
        'Critical',
        eventRecord.Id,
        'Signature provider event failed: ' + eventRecord.Event_Type__c,
        nowValue
      );

    for (Partner_Onboarding_Task__c task : [
      SELECT Id, Title__c
      FROM Partner_Onboarding_Task__c
      WHERE
        Status__c NOT IN ('Complete', 'Waived', 'Cancelled')
        AND Due_On__c < :nowValue
      WITH SYSTEM_MODE
      LIMIT 200
    ])
      add(
        candidates,
        'OVERDUE:' + task.Id,
        'Overdue Work',
        'High',
        task.Id,
        'Overdue onboarding task: ' + task.Title__c,
        nowValue
      );

    Date today = Date.today();
    Date evidenceWarningDate = today.addDays(30);
    for (Partner_Document__c document : [
      SELECT Id, Requirement__r.Document_Type__c, Status__c, Expiry_Date__c
      FROM Partner_Document__c
      WHERE
        Status__c IN ('Accepted', 'Expired')
        AND Superseded_By__c = NULL
        AND Expiry_Date__c <= :evidenceWarningDate
      WITH SYSTEM_MODE
      ORDER BY Expiry_Date__c ASC
      LIMIT 200
    ]) {
      Boolean expired = document.Expiry_Date__c < today;
      add(
        candidates,
        'DOCUMENT_EXPIRY:' + document.Id,
        expired ? 'Expired Partner Evidence' : 'Partner Evidence Expiring',
        expired ? 'Critical' : 'High',
        document.Id,
        document.Requirement__r.Document_Type__c +
          (expired ? ' expired on ' : ' expires on ') +
          String.valueOf(document.Expiry_Date__c) +
          '.',
        nowValue
      );
    }

    for (Partner_Document_Requirement__c requirement : [
      SELECT Id, Document_Type__c, Due_On__c
      FROM Partner_Document_Requirement__c
      WHERE
        Due_On__c < :today
        AND Status__c NOT IN ('Accepted', 'Waived', 'Not Applicable')
      WITH SYSTEM_MODE
      ORDER BY Due_On__c ASC
      LIMIT 200
    ])
      add(
        candidates,
        'DOCUMENT_REQUIREMENT:' + requirement.Id,
        'Overdue Partner Evidence',
        'High',
        requirement.Id,
        requirement.Document_Type__c +
          ' was due on ' +
          String.valueOf(requirement.Due_On__c) +
          '.',
        nowValue
      );

    for (Partner_Onboarding__c onboarding : [
      SELECT Id, Recertification_Due_On__c
      FROM Partner_Onboarding__c
      WHERE Status__c = 'Active' AND Recertification_Due_On__c < :today
      WITH SYSTEM_MODE
      LIMIT 200
    ])
      add(
        candidates,
        'RECERT:' + onboarding.Id,
        'Recertification Breach',
        'Critical',
        onboarding.Id,
        'Partner recertification is overdue since ' +
          String.valueOf(onboarding.Recertification_Due_On__c) +
          '.',
        nowValue
      );

    for (AsyncApexJob job : [
      SELECT Id, Status, ExtendedStatus, ApexClass.Name
      FROM AsyncApexJob
      WHERE
        Status IN ('Failed', 'Aborted')
        AND CompletedDate >= :recent
        AND ApexClass.Name IN (
          'PartnerLifecycleGovernanceBatch',
          'PartnerAccessProvisioningQueueable'
        )
      WITH SYSTEM_MODE
      LIMIT 100
    ])
      add(
        candidates,
        'ASYNC:' + job.Id,
        'Scheduled Job Failure',
        'Critical',
        job.Id,
        job.ApexClass.Name + ' ' + job.Status + ': ' + job.ExtendedStatus,
        nowValue
      );

    resolveClearedAlerts(candidates.keySet(), nowValue);
    if (candidates.isEmpty())
      return new List<Partner_Operational_Alert__c>();
    Map<String, Partner_Operational_Alert__c> existing = new Map<String, Partner_Operational_Alert__c>();
    for (Partner_Operational_Alert__c alert : [
      SELECT
        Id,
        Alert_Key__c,
        Occurrence_Count__c,
        First_Detected_On__c,
        Status__c
      FROM Partner_Operational_Alert__c
      WHERE Alert_Key__c IN :candidates.keySet()
      WITH SYSTEM_MODE
    ])
      existing.put(alert.Alert_Key__c, alert);
    for (String key : candidates.keySet()) {
      Partner_Operational_Alert__c candidate = candidates.get(key);
      if (existing.containsKey(key)) {
        candidate.Id = existing.get(key).Id;
        candidate.Occurrence_Count__c =
          existing.get(key).Occurrence_Count__c + 1;
        candidate.First_Detected_On__c = existing.get(key).First_Detected_On__c;
        if (existing.get(key).Status__c == 'Acknowledged')
          candidate.Status__c = 'Acknowledged';
      }
    }
    List<Partner_Operational_Alert__c> alerts = candidates.values();
    Database.upsert(
      alerts,
      Partner_Operational_Alert__c.Fields.Alert_Key__c,
      AccessLevel.SYSTEM_MODE
    );
    Set<Id> alertIds = new Map<Id, Partner_Operational_Alert__c>(alerts)
      .keySet();
    PartnerAlertNotificationService.notifyNewAlerts(alertIds);
    return alerts;
  }

  private static void resolveClearedAlerts(
    Set<String> activeKeys,
    Datetime resolvedOn
  ) {
    List<Partner_Operational_Alert__c> resolved = new List<Partner_Operational_Alert__c>();
    for (Partner_Operational_Alert__c alert : [
      SELECT Id, Alert_Key__c, Status__c
      FROM Partner_Operational_Alert__c
      WHERE Status__c IN ('Open', 'Acknowledged')
      WITH SYSTEM_MODE
      LIMIT 1000
    ]) {
      if (activeKeys.contains(alert.Alert_Key__c))
        continue;
      alert.Status__c = 'Resolved';
      alert.Resolved_On__c = resolvedOn;
      resolved.add(alert);
    }
    if (!resolved.isEmpty())
      Database.update(resolved, AccessLevel.SYSTEM_MODE);
  }

  public static Partner_Operational_Alert__c acknowledge(Id alertId) {
    if (
      !FeatureManagement.checkPermission(
        'PartnerSync_Manage_Operational_Alerts'
      ) && !(Test.isRunningTest() && testManageAuthority)
    ) {
      throw new OperationalAlertException(
        'Operational alert management authority is required.'
      );
    }
    Partner_Operational_Alert__c alert = [
      SELECT Id, Status__c
      FROM Partner_Operational_Alert__c
      WHERE Id = :alertId
      WITH SYSTEM_MODE
      LIMIT 1
      FOR UPDATE
    ];
    alert.Status__c = 'Acknowledged';
    alert.Acknowledged_By__c = UserInfo.getUserId();
    alert.Acknowledged_On__c = System.now();
    Database.update(alert, AccessLevel.SYSTEM_MODE);
    return alert;
  }

  public void execute(SchedulableContext context) {
    scan();
  }

  private static void add(
    Map<String, Partner_Operational_Alert__c> alerts,
    String key,
    String typeName,
    String severity,
    Id sourceId,
    String message,
    Datetime detectedOn
  ) {
    alerts.put(
      key,
      new Partner_Operational_Alert__c(
        Alert_Key__c = key,
        Alert_Type__c = typeName,
        Severity__c = severity,
        Status__c = 'Open',
        Source_Record_Id__c = String.valueOf(sourceId),
        Message__c = message,
        Occurrence_Count__c = 1,
        First_Detected_On__c = detectedOn,
        Last_Detected_On__c = detectedOn
      )
    );
  }

  public class OperationalAlertException extends Exception {
  }
}
