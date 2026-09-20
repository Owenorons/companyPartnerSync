/** Read-only subscriber readiness diagnostics for the PartnerSync setup experience. */
@SuppressWarnings('PMD.ApexCRUDViolation')
public with sharing class PartnerSyncSetupController {
  @TestVisible
  private static Set<String> installedPermissionGroupsOverride;
  @TestVisible
  private static Integer onboardingRuleCountOverride;
  @TestVisible
  private static Integer liveSiteCountOverride;
  @TestVisible
  private static Integer activeAiProviderCountOverride;

  private static final String ADMIN_PERMISSION_SET = 'PartnerSync_Internal_Admin';
  private static final Map<String, String> OPERATIONAL_SCHEDULES = new Map<String, String>{
    'PartnerSync Lifecycle Governance Daily' => '0 0 2 * * ?',
    'PartnerSync Operational Alerts Hourly' => '0 0 * * * ?',
    'PartnerSync Provisioning Reconciliation' => '0 15 * * * ?',
    'PartnerSync Deal Expiry' => '0 30 2 * * ?',
    'PartnerSync Partner Share Cleanup' => '0 45 2 * * ?'
  };

  /**
   * Runs the full set of subscriber-org readiness checks (core metadata,
   * administrator access, permission groups, onboarding policy, scheduled
   * automation, Experience Cloud, AI configuration) and summarizes them.
   * Requires PartnerSync setup administrator access.
   *
   * @return The readiness report, with one check result per readiness area.
   */
  @AuraEnabled(cacheable=true)
  public static ReadinessReport getReadiness() {
    assertSetupAdministrator();

    ReadinessReport report = new ReadinessReport();
    report.generatedAt = System.now();
    report.checks = new List<ReadinessCheck>{
      coreMetadataCheck(),
      administratorCheck(),
      permissionGroupCheck(),
      onboardingPolicyCheck(),
      scheduledAutomationCheck(),
      experienceCloudCheck(),
      aiConfigurationCheck()
    };

    Integer readyCount = 0;
    Integer actionCount = 0;
    for (ReadinessCheck check : report.checks) {
      if (check.status == 'READY') {
        readyCount++;
      } else if (check.status == 'ACTION_REQUIRED') {
        actionCount++;
      }
    }

    report.readyCount = readyCount;
    report.totalCount = report.checks.size();
    report.coreReady = actionCount == 0;
    report.portalReady =
      report.coreReady &&
      findStatus(report.checks, 'experience-cloud') == 'READY';
    return report;
  }

  /**
   * Schedules (or re-schedules, if not already active) the required
   * PartnerSync operational automation jobs, aborting any stale scheduled
   * instances first, then returns the refreshed readiness report. Requires
   * PartnerSync setup administrator access.
   *
   * @return The readiness report after the automation jobs have been scheduled.
   */
  @AuraEnabled
  public static ReadinessReport configureOperationalAutomation() {
    assertSetupAdministrator();
    Map<String, Schedulable> jobs = operationalJobs();
    Set<String> jobNames = jobs.keySet();
    Set<String> activeJobNames = new Set<String>();
    for (CronTrigger scheduledJob : [
      SELECT Id, CronJobDetail.Name, State
      FROM CronTrigger
      WHERE
        CronJobDetail.Name IN :jobNames
        AND State IN ('WAITING', 'ACQUIRED', 'PAUSED', 'BLOCKED')
    ]) {
      if (scheduledJob.State == 'WAITING' || scheduledJob.State == 'ACQUIRED') {
        activeJobNames.add(scheduledJob.CronJobDetail.Name);
      } else {
        System.abortJob(scheduledJob.Id);
      }
    }

    for (String jobName : jobs.keySet()) {
      if (!activeJobNames.contains(jobName)) {
        System.schedule(
          jobName,
          OPERATIONAL_SCHEDULES.get(jobName),
          jobs.get(jobName)
        );
      }
    }
    return getReadiness();
  }

  private static ReadinessCheck coreMetadataCheck() {
    List<Schema.SObjectType> requiredObjects = new List<Schema.SObjectType>{
      Partner_Onboarding__c.SObjectType,
      Deal_Registration__c.SObjectType,
      MDF_Request__c.SObjectType
    };
    List<String> missing = new List<String>();
    for (Schema.SObjectType objectType : requiredObjects) {
      try {
        if (String.isBlank(objectType.getDescribe().getName())) {
          missing.add('Unknown packaged object');
        }
      } catch (Exception describeError) {
        missing.add('Unavailable packaged object');
      }
    }

    return missing.isEmpty()
      ? check(
          'core-metadata',
          'Core application',
          'READY',
          'Required PartnerSync business objects are installed.',
          'No action required.'
        )
      : check(
          'core-metadata',
          'Core application',
          'ACTION_REQUIRED',
          'Required metadata is missing: ' + String.join(missing, ', '),
          'Reinstall or upgrade the PartnerSync managed package.'
        );
  }

  private static ReadinessCheck administratorCheck() {
    return check(
      'administrator-access',
      'Setup administrator',
      'READY',
      'The current user has PartnerSync setup access.',
      'Keep setup access limited to authorised internal administrators.'
    );
  }

  private static ReadinessCheck permissionGroupCheck() {
    Set<String> requiredGroups = new Set<String>{
      'PSG_Internal_Administrator',
      'PSG_Channel_Manager',
      'PSG_Partner_User'
    };
    Set<String> installedGroups = installedPermissionGroupsOverride;
    if (installedGroups == null) {
      installedGroups = new Set<String>();
      for (PermissionSetGroup groupRecord : [
        SELECT DeveloperName
        FROM PermissionSetGroup
        WHERE DeveloperName IN :requiredGroups
      ]) {
        installedGroups.add(groupRecord.DeveloperName);
      }
    }

    requiredGroups.removeAll(installedGroups);
    return requiredGroups.isEmpty()
      ? check(
          'permission-groups',
          'Persona permissions',
          'READY',
          'Core administrator, channel manager, and partner permission groups are available.',
          'Assign groups only after confirming each user persona and licence.'
        )
      : check(
          'permission-groups',
          'Persona permissions',
          'ACTION_REQUIRED',
          'Missing permission groups: ' +
          String.join(new List<String>(requiredGroups), ', '),
          'Repair the package installation before assigning users.'
        );
  }

  private static ReadinessCheck onboardingPolicyCheck() {
    Integer ruleCount = onboardingRuleCountOverride == null
      ? [SELECT COUNT() FROM Partner_Document_Requirement_Rule__mdt]
      : onboardingRuleCountOverride;
    return ruleCount > 0
      ? check(
          'onboarding-policy',
          'Onboarding policy',
          'READY',
          String.valueOf(ruleCount) +
          ' document requirement rule(s) are configured.',
          'Review the rules against the subscriber\'s partner programme.'
        )
      : check(
          'onboarding-policy',
          'Onboarding policy',
          'ACTION_REQUIRED',
          'No partner document requirement rules are configured.',
          'Create at least one requirement rule before onboarding partners.'
        );
  }

  private static ReadinessCheck experienceCloudCheck() {
    try {
      Integer siteCount = liveSiteCountOverride == null
        ? Database.countQuery(
            'SELECT COUNT() FROM Network WHERE Status = \'Live\''
          )
        : liveSiteCountOverride;
      return siteCount > 0
        ? check(
            'experience-cloud',
            'Experience Cloud portal',
            'READY',
            String.valueOf(siteCount) +
            ' live Experience Cloud site(s) detected.',
            'Confirm a live site uses the PartnerSync template and external permission model.'
          )
        : check(
            'experience-cloud',
            'Experience Cloud portal',
            'WARNING',
            'No live Experience Cloud site was detected. The core application can still be used.',
            'If a portal was purchased, enable Digital Experiences, create the site, validate it, and publish it.'
          );
    } catch (Exception queryError) {
      return check(
        'experience-cloud',
        'Experience Cloud portal',
        'WARNING',
        'Experience Cloud availability could not be verified.',
        'Confirm the org edition, Experience Cloud licences, Digital Experiences domain, and administrator access.'
      );
    }
  }

  private static ReadinessCheck scheduledAutomationCheck() {
    Set<String> requiredJobs = new Set<String>();
    requiredJobs.addAll(OPERATIONAL_SCHEDULES.keySet());
    try {
      Set<String> activeJobs = new Set<String>();
      for (CronTrigger scheduledJob : [
        SELECT CronJobDetail.Name, State, NextFireTime
        FROM CronTrigger
        WHERE
          CronJobDetail.Name IN :requiredJobs
          AND State IN ('WAITING', 'ACQUIRED')
      ]) {
        if (scheduledJob.NextFireTime != null) {
          activeJobs.add(scheduledJob.CronJobDetail.Name);
        }
      }
      requiredJobs.removeAll(activeJobs);
      return requiredJobs.isEmpty()
        ? check(
            'scheduled-automation',
            'Operational automation',
            'READY',
            'Lifecycle, alerting, provisioning, deal expiry, and sharing cleanup jobs are scheduled.',
            'Monitor failures through PartnerSync operational alerts.'
          )
        : check(
            'scheduled-automation',
            'Operational automation',
            'ACTION_REQUIRED',
            'Missing or inactive jobs: ' +
            String.join(new List<String>(requiredJobs), ', '),
            'Run scripts/apex/schedule-partnersync-operations.apex once in the subscriber org.'
          );
    } catch (Exception queryError) {
      return check(
        'scheduled-automation',
        'Operational automation',
        'WARNING',
        'Scheduled PartnerSync automation could not be verified.',
        'Grant the setup administrator access to review scheduled jobs, then run the check again.'
      );
    }
  }

  private static ReadinessCheck aiConfigurationCheck() {
    Integer activeProviders = activeAiProviderCountOverride == null
      ? [SELECT COUNT() FROM AI_Provider_Config__mdt WHERE Active__c = TRUE]
      : activeAiProviderCountOverride;
    return activeProviders > 0
      ? check(
          'ai-configuration',
          'AI integration',
          'READY',
          String.valueOf(activeProviders) +
          ' AI provider configuration(s) are active.',
          'Test provider credentials before enabling AI-assisted workflows.'
        )
      : check(
          'ai-configuration',
          'AI integration',
          'WARNING',
          'No active AI provider is configured. AI features remain optional.',
          'Activate and test a provider only when the subscriber intends to use AI features.'
        );
  }

  private static ReadinessCheck check(
    String key,
    String label,
    String status,
    String detail,
    String action
  ) {
    ReadinessCheck result = new ReadinessCheck();
    result.key = key;
    result.label = label;
    result.status = status;
    result.detail = detail;
    result.action = action;
    return result;
  }

  private static void assertSetupAdministrator() {
    if (
      !PartnerAccessService.isInternalUser() ||
      !PermissionService.hasPermissionSet(ADMIN_PERMISSION_SET)
    ) {
      throw new PartnerSyncHandledException(
        'Assign the PartnerSync Internal Admin permission set to manage setup.'
      );
    }
  }

  private static Map<String, Schedulable> operationalJobs() {
    return new Map<String, Schedulable>{
      'PartnerSync Lifecycle Governance Daily' => new PartnerLifecycleGovernanceBatch(),
      'PartnerSync Operational Alerts Hourly' => new PartnerOperationalAlertService(),
      'PartnerSync Provisioning Reconciliation' => new PartnerProvisioningReconciler(),
      'PartnerSync Deal Expiry' => new DealExpiryBatch(),
      'PartnerSync Partner Share Cleanup' => new PartnerShareCleanupBatch()
    };
  }

  private static String findStatus(
    List<ReadinessCheck> checks,
    String targetKey
  ) {
    for (ReadinessCheck check : checks) {
      if (check.key == targetKey) {
        return check.status;
      }
    }
    return null;
  }

  /**
   * Summary of a subscriber org's PartnerSync setup readiness, made up of
   * individual per-area ReadinessCheck results.
   */
  public class ReadinessReport {
    /** When this report was generated. */
    @AuraEnabled
    public Datetime generatedAt;
    /** The individual readiness checks that make up this report. */
    @AuraEnabled
    public List<ReadinessCheck> checks;
    /** The number of checks with status READY. */
    @AuraEnabled
    public Integer readyCount;
    /** The total number of checks run. */
    @AuraEnabled
    public Integer totalCount;
    /** True when no check has status ACTION_REQUIRED. */
    @AuraEnabled
    public Boolean coreReady;
    /** True when coreReady is true and the Experience Cloud check is READY. */
    @AuraEnabled
    public Boolean portalReady;
  }

  /**
   * The result of a single readiness check for one setup area.
   */
  public class ReadinessCheck {
    /** Stable identifier for the readiness area (e.g. 'core-metadata'). */
    @AuraEnabled
    public String key;
    /** Human-readable label for the readiness area. */
    @AuraEnabled
    public String label;
    /** The check outcome: READY, ACTION_REQUIRED, or WARNING. */
    @AuraEnabled
    public String status;
    /** A description of the current state for this readiness area. */
    @AuraEnabled
    public String detail;
    /** The recommended next action for this readiness area. */
    @AuraEnabled
    public String action;
  }
}
