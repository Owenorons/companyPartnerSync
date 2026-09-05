/*
 * Assembles the internal-user dashboard: org-wide review-queue counts and
 * unread notifications for the signed-in employee. Mirrors
 * PartnerDashboardService's shape, but every count here is scoped to
 * review queues an internal user may or may not be permissioned to see,
 * rather than to a single partner's own records.
 */
public with sharing class InternalDashboardService {
  private static final Set<String> PENDING_DEAL_STATUSES = new Set<String>{
    'Submitted',
    'Under Review'
  };

  public static InternalDashboardDTO getDashboard() {
    PartnerAccessService.assertInternalUser();

    InternalDashboardDTO dto = new InternalDashboardDTO();
    dto.userName = UserInfo.getName();
    dto.alerts = new List<String>();

    dto.pendingDealReviewCount = 0;

    // Silently report zero rather than throwing when the user lacks the
    // review permission — this dashboard is shared by all internal users,
    // not just reviewers, and a permission gap here should not surface as
    // an error tile.
    if (PartnerPermissionService.canViewAllDeals()) {
      List<DealReviewListDTO> reviewQueue = DealReviewService.getReviewQueue();

      for (DealReviewListDTO deal : reviewQueue) {
        if (PENDING_DEAL_STATUSES.contains(deal.status)) {
          dto.pendingDealReviewCount++;
        }
      }
    }

    dto.pendingMdfReviewCount = 0;

    if (PartnerPermissionService.canViewAllMdf()) {
      dto.pendingMdfReviewCount = MDFSelector.selectReviewQueue().size();
    }

    dto.unreadNotificationCount = 0;
    if (
      Partner_Notification__c.SObjectType.getDescribe().isAccessible() &&
      Partner_Notification__c.Recipient_User__c.getDescribe().isAccessible()
    ) {
      dto.unreadNotificationCount = NotificationSelector.countUnreadForUser(
        UserInfo.getUserId()
      );
    }

    addDealAlert(dto.alerts, dto.pendingDealReviewCount);
    addMdfAlert(dto.alerts, dto.pendingMdfReviewCount);
    addNotificationAlert(dto.alerts, dto.unreadNotificationCount);
    addOnboardingOperations(dto);
    addComplianceOperations(dto);
    addOperationalAlerts(dto);
    addUnifiedWorkQueue(dto);

    return dto;
  }

  private static void addUnifiedWorkQueue(InternalDashboardDTO dto) {
    dto.unifiedWorkItems = new List<UnifiedWorkItemDTO>();
    for (OnboardingWorkItemDTO source : dto.onboardingWorkItems)
      addUnifiedItem(
        dto,
        source.recordId,
        source.onboardingId,
        'Onboarding',
        source.queueType,
        source.title,
        source.status,
        source.priority,
        source.dueOn
      );

    for (PartnerComplianceItemDTO source : dto.complianceItems)
      addUnifiedItem(
        dto,
        source.recordId,
        source.onboardingId,
        'Compliance',
        source.category,
        source.documentType + ' — ' + source.message,
        source.status,
        source.severity,
        source.dueOn == null
          ? null
          : Datetime.newInstance(source.dueOn, Time.newInstance(0, 0, 0, 0))
      );

    if (
      PermissionService.hasAnyPermissionSet(
        new List<String>{
          'PartnerSync_Channel_Manager',
          'PartnerSync_Internal_Admin'
        }
      )
    )
      for (Partner_Access_Request__c request : [
        SELECT Id, Onboarding__c, Access_Bundle__c, Status__c, CreatedDate
        FROM Partner_Access_Request__c
        WHERE
          Status__c IN (
            'Pending Approval',
            'Approved',
            'Provisioning',
            'Failed'
          )
        WITH USER_MODE
        ORDER BY CreatedDate ASC
        LIMIT 50
      ])
        addUnifiedItem(
          dto,
          request.Id,
          request.Onboarding__c,
          'Access',
          'Access Request',
          request.Access_Bundle__c + ' access',
          request.Status__c,
          request.Status__c == 'Failed' ? 'Critical' : 'High',
          request.CreatedDate
        );

    if (PartnerPermissionService.canViewAllDeals())
      for (DealReviewListDTO deal : DealReviewService.getReviewQueue())
        if (PENDING_DEAL_STATUSES.contains(deal.status))
          addUnifiedItem(
            dto,
            deal.dealId,
            null,
            'Deals',
            'Deal Review',
            deal.dealNumber + ' — ' + deal.customerName,
            deal.status,
            deal.conflictStatus == 'Blocked' ? 'Critical' : 'High',
            deal.submittedOn
          );

    if (PartnerPermissionService.canViewAllMdf())
      for (MDF_Request__c request : MDFSelector.selectReviewQueue())
        addUnifiedItem(
          dto,
          request.Id,
          null,
          'MDF',
          'MDF Review',
          request.Name + ' — ' + request.Campaign_Name__c,
          request.Status__c,
          'Medium',
          request.Activity_Start_Date__c == null
            ? null
            : Datetime.newInstance(
                request.Activity_Start_Date__c,
                Time.newInstance(0, 0, 0, 0)
              )
        );

    if (
      PermissionService.hasAnyPermissionSet(
        new List<String>{ 'PartnerSync_Event_Operations' }
      )
    ) {
      for (Event_DLQ__c deadLetter : [
        SELECT Id, Event_Type__c, Status__c, Last_Retry_On__c
        FROM Event_DLQ__c
        WHERE Status__c IN ('New', 'Failed')
        WITH USER_MODE
        ORDER BY CreatedDate ASC
        LIMIT 25
      ])
        addUnifiedItem(
          dto,
          deadLetter.Id,
          null,
          'Events',
          'Dead Letter',
          deadLetter.Event_Type__c + ' processing failure',
          deadLetter.Status__c,
          'Critical',
          deadLetter.Last_Retry_On__c
        );
    }
    if (
      FeatureManagement.checkPermission('PartnerSync_Manage_Operational_Alerts')
    )
      for (Partner_Alert_Delivery_Attempt__c attempt : [
        SELECT Id, Alert__c, Channel__c, Recipient__c, Status__c, Retry_On__c
        FROM Partner_Alert_Delivery_Attempt__c
        WHERE Status__c = 'Failed'
        WITH USER_MODE
        ORDER BY Attempted_On__c DESC
        LIMIT 50
      ])
        addUnifiedItem(
          dto,
          attempt.Id,
          attempt.Alert__c,
          'Notifications',
          'Delivery Failure',
          attempt.Channel__c + ' delivery to ' + attempt.Recipient__c,
          attempt.Status__c,
          'High',
          attempt.Retry_On__c
        );
    dto.unifiedWorkCount = dto.unifiedWorkItems.size();
  }

  private static void addUnifiedItem(
    InternalDashboardDTO dto,
    Id recordId,
    Id parentId,
    String domain,
    String workType,
    String title,
    String status,
    String priority,
    Datetime dueOn
  ) {
    UnifiedWorkItemDTO item = new UnifiedWorkItemDTO();
    item.recordId = recordId;
    item.parentId = parentId;
    item.domain = domain;
    item.workType = workType;
    item.title = title;
    item.status = status;
    item.priority = priority;
    item.dueOn = dueOn;
    dto.unifiedWorkItems.add(item);
  }

  private static void addOperationalAlerts(InternalDashboardDTO dto) {
    dto.openOperationalAlertCount = 0;
    dto.operationalAlerts = new List<OperationalAlertDTO>();
    if (
      !FeatureManagement.checkPermission(
        'PartnerSync_Manage_Operational_Alerts'
      )
    )
      return;
    for (Partner_Operational_Alert__c alert : [
      SELECT
        Id,
        Alert_Type__c,
        Severity__c,
        Message__c,
        Occurrence_Count__c,
        Last_Detected_On__c,
        Status__c,
        Resolved_On__c
      FROM Partner_Operational_Alert__c
      WITH USER_MODE
      ORDER BY Last_Detected_On__c DESC
      LIMIT 100
    ]) {
      OperationalAlertDTO item = new OperationalAlertDTO();
      item.recordId = alert.Id;
      item.alertType = alert.Alert_Type__c;
      item.severity = alert.Severity__c;
      item.message = alert.Message__c;
      item.occurrenceCount = alert.Occurrence_Count__c.intValue();
      item.lastDetectedOn = alert.Last_Detected_On__c;
      item.status = alert.Status__c;
      item.resolvedOn = alert.Resolved_On__c;
      item.canAcknowledge = alert.Status__c == 'Open';
      item.transitionLabel = alert.Status__c == 'Resolved'
        ? 'Reopen'
        : 'Resolve';
      dto.operationalAlerts.add(item);
      if (alert.Status__c == 'Open')
        dto.openOperationalAlertCount++;
    }
    if (dto.openOperationalAlertCount > 0)
      dto.alerts.add(
        dto.openOperationalAlertCount +
        ' operational alerts require acknowledgement.'
      );
  }

  private static void addOnboardingOperations(InternalDashboardDTO dto) {
    dto.blockedOnboardingCount = 0;
    dto.onboardingWorkCount = 0;
    dto.provisioningFailureCount = 0;
    dto.recertificationDueCount = 0;
    dto.totalOnboardingCount = 0;
    dto.activeOnboardingCount = 0;
    dto.onboardingCompletionRate = 0;
    dto.averageActivationDays = 0;
    dto.overdueOnboardingTaskCount = 0;
    dto.onboardingBottleneckStage = 'No active onboarding';
    dto.onboardingBottleneckCount = 0;
    dto.onboardingWorkItems = new List<OnboardingWorkItemDTO>();
    if (
      !PermissionService.hasAnyPermissionSet(
        new List<String>{
          'PartnerSync_Channel_Manager',
          'PartnerSync_Internal_Admin'
        }
      )
    )
      return;

    addOnboardingOutcomeMetrics(dto);

    dto.blockedOnboardingCount = [
      SELECT COUNT()
      FROM Partner_Onboarding__c
      WHERE Status__c = 'Onboarding' AND Activation_Gate_Status__c = 'Blocked'
      WITH USER_MODE
    ];
    Date today = Date.today();
    Datetime nowValue = System.now();
    Date recertificationWindow = today.addDays(30);
    dto.recertificationDueCount = [
      SELECT COUNT()
      FROM Partner_Onboarding__c
      WHERE
        Status__c = 'Active'
        AND Recertification_Due_On__c <= :recertificationWindow
      WITH USER_MODE
    ];

    for (Partner_Onboarding_Task__c task : [
      SELECT Id, Onboarding__c, Title__c, Status__c, Due_On__c
      FROM Partner_Onboarding_Task__c
      WHERE
        Status__c NOT IN ('Complete', 'Waived', 'Cancelled')
        AND Due_On__c < :nowValue
      WITH USER_MODE
      ORDER BY Due_On__c ASC
      LIMIT 10
    ])
      addItem(
        dto,
        task.Id,
        task.Onboarding__c,
        'Overdue Task',
        task.Title__c,
        task.Status__c,
        'High',
        task.Due_On__c
      );

    for (Partner_Approval_Step__c step : [
      SELECT Id, Plan__r.Onboarding__c, Dimension__c, Status__c
      FROM Partner_Approval_Step__c
      WHERE Status__c = 'Pending'
      WITH USER_MODE
      ORDER BY Sequence__c ASC
      LIMIT 10
    ])
      addItem(
        dto,
        step.Id,
        step.Plan__r.Onboarding__c,
        'Approval',
        step.Dimension__c + ' approval',
        step.Status__c,
        'Medium',
        null
      );

    for (Partner_Assessment_Finding__c finding : [
      SELECT
        Id,
        Assessment__r.Onboarding__c,
        Severity__c,
        Status__c,
        Description__c
      FROM Partner_Assessment_Finding__c
      WHERE Status__c = 'Open' AND Blocking__c = TRUE
      WITH USER_MODE
      ORDER BY Severity__c DESC
      LIMIT 10
    ])
      addItem(
        dto,
        finding.Id,
        finding.Assessment__r.Onboarding__c,
        'Risk Finding',
        finding.Description__c,
        finding.Status__c,
        finding.Severity__c,
        null
      );

    for (Partner_Provisioning_Attempt__c attempt : [
      SELECT
        Id,
        Access_Request__r.Onboarding__c,
        Outcome__c,
        Status__c,
        Started_On__c
      FROM Partner_Provisioning_Attempt__c
      WHERE Status__c = 'Failed'
      WITH USER_MODE
      ORDER BY Started_On__c DESC
      LIMIT 10
    ]) {
      dto.provisioningFailureCount++;
      addItem(
        dto,
        attempt.Id,
        attempt.Access_Request__r.Onboarding__c,
        'Provisioning',
        attempt.Outcome__c,
        attempt.Status__c,
        'High',
        attempt.Started_On__c
      );
    }

    for (Partner_Onboarding__c onboarding : [
      SELECT Id, Status__c, Recertification_Due_On__c
      FROM Partner_Onboarding__c
      WHERE
        Status__c = 'Active'
        AND Recertification_Due_On__c <= :recertificationWindow
      WITH USER_MODE
      ORDER BY Recertification_Due_On__c ASC
      LIMIT 10
    ])
      addItem(
        dto,
        onboarding.Id,
        onboarding.Id,
        'Recertification',
        'Partner recertification',
        onboarding.Status__c,
        onboarding.Recertification_Due_On__c < today ? 'High' : 'Medium',
        Datetime.newInstance(
          onboarding.Recertification_Due_On__c,
          Time.newInstance(0, 0, 0, 0)
        )
      );

    dto.onboardingWorkCount = dto.onboardingWorkItems.size();
    if (dto.onboardingWorkCount > 0)
      dto.alerts.add(
        dto.onboardingWorkCount + ' onboarding work items require attention.'
      );
  }

  private static void addComplianceOperations(InternalDashboardDTO dto) {
    dto.expiredEvidenceCount = 0;
    dto.expiringEvidenceCount = 0;
    dto.overdueRequirementCount = 0;
    dto.complianceItems = new List<PartnerComplianceItemDTO>();
    if (
      !PermissionService.hasAnyPermissionSet(
        new List<String>{
          'PartnerSync_Channel_Manager',
          'PartnerSync_Internal_Admin'
        }
      )
    )
      return;

    Date today = Date.today();
    Date warningDate = today.addDays(30);
    dto.expiredEvidenceCount = [
      SELECT COUNT()
      FROM Partner_Document__c
      WHERE
        Status__c = 'Accepted'
        AND Superseded_By__c = NULL
        AND Expiry_Date__c < :today
      WITH USER_MODE
    ];
    dto.expiringEvidenceCount = [
      SELECT COUNT()
      FROM Partner_Document__c
      WHERE
        Status__c = 'Accepted'
        AND Superseded_By__c = NULL
        AND Expiry_Date__c >= :today
        AND Expiry_Date__c <= :warningDate
      WITH USER_MODE
    ];
    dto.overdueRequirementCount = [
      SELECT COUNT()
      FROM Partner_Document_Requirement__c
      WHERE
        Due_On__c < :today
        AND Status__c NOT IN ('Accepted', 'Waived', 'Not Applicable')
      WITH USER_MODE
    ];

    for (Partner_Document__c document : [
      SELECT
        Id,
        Onboarding__c,
        Requirement__r.Document_Type__c,
        Status__c,
        Expiry_Date__c
      FROM Partner_Document__c
      WHERE
        Status__c = 'Accepted'
        AND Superseded_By__c = NULL
        AND Expiry_Date__c <= :warningDate
      WITH USER_MODE
      ORDER BY Expiry_Date__c ASC
      LIMIT 50
    ]) {
      Boolean expired = document.Expiry_Date__c < today;
      addComplianceItem(
        dto,
        document.Id,
        document.Onboarding__c,
        expired ? 'Expired Evidence' : 'Expiring Evidence',
        document.Requirement__r.Document_Type__c,
        expired ? 'Expired' : 'Accepted',
        expired ? 'Critical' : 'High',
        document.Expiry_Date__c,
        expired
          ? 'Replacement evidence is required.'
          : 'Renewal is due within 30 days.'
      );
    }

    for (Partner_Document_Requirement__c requirement : [
      SELECT Id, Onboarding__c, Document_Type__c, Status__c, Due_On__c
      FROM Partner_Document_Requirement__c
      WHERE
        Due_On__c < :today
        AND Status__c NOT IN ('Accepted', 'Waived', 'Not Applicable')
      WITH USER_MODE
      ORDER BY Due_On__c ASC
      LIMIT 50
    ])
      addComplianceItem(
        dto,
        requirement.Id,
        requirement.Onboarding__c,
        'Overdue Requirement',
        requirement.Document_Type__c,
        requirement.Status__c,
        'High',
        requirement.Due_On__c,
        'Required evidence is overdue.'
      );

    if (!dto.complianceItems.isEmpty())
      dto.alerts.add(
        dto.complianceItems.size() +
        ' partner compliance items require attention.'
      );
  }

  private static void addComplianceItem(
    InternalDashboardDTO dto,
    Id recordId,
    Id onboardingId,
    String category,
    String documentType,
    String status,
    String severity,
    Date dueOn,
    String message
  ) {
    PartnerComplianceItemDTO item = new PartnerComplianceItemDTO();
    item.recordId = recordId;
    item.onboardingId = onboardingId;
    item.category = category;
    item.documentType = documentType;
    item.status = status;
    item.severity = severity;
    item.dueOn = dueOn;
    item.message = message;
    dto.complianceItems.add(item);
  }

  private static void addOnboardingOutcomeMetrics(InternalDashboardDTO dto) {
    Map<String, Integer> openByStage = new Map<String, Integer>();
    Decimal activationDays = 0;
    Integer activationSamples = 0;
    dto.totalOnboardingCount = [
      SELECT COUNT()
      FROM Partner_Onboarding__c
      WITH USER_MODE
    ];
    dto.activeOnboardingCount = [
      SELECT COUNT()
      FROM Partner_Onboarding__c
      WHERE Status__c = 'Active'
      WITH USER_MODE
    ];

    for (Partner_Onboarding__c onboarding : [
      SELECT Status__c, Current_Stage__c, CreatedDate, Activated_On__c
      FROM Partner_Onboarding__c
      WHERE Status__c IN ('Active', 'Onboarding')
      WITH USER_MODE
      ORDER BY CreatedDate DESC
      LIMIT 5000
    ]) {
      if (onboarding.Status__c == 'Active') {
        if (onboarding.Activated_On__c != null) {
          activationDays += onboarding.CreatedDate.date()
            .daysBetween(onboarding.Activated_On__c.date());
          activationSamples++;
        }
      } else if (onboarding.Status__c == 'Onboarding') {
        String stage = String.isBlank(onboarding.Current_Stage__c)
          ? 'Unassigned'
          : onboarding.Current_Stage__c;
        openByStage.put(
          stage,
          (openByStage.containsKey(stage) ? openByStage.get(stage) : 0) + 1
        );
      }
    }

    dto.onboardingCompletionRate = dto.totalOnboardingCount == 0
      ? 0
      : Decimal.valueOf(dto.activeOnboardingCount) / dto.totalOnboardingCount;
    dto.averageActivationDays = activationSamples == 0
      ? 0
      : (activationDays / activationSamples).setScale(1);

    for (String stage : openByStage.keySet()) {
      Integer stageCount = openByStage.get(stage);
      if (stageCount > dto.onboardingBottleneckCount) {
        dto.onboardingBottleneckStage = stage;
        dto.onboardingBottleneckCount = stageCount;
      }
    }

    Datetime currentTime = System.now();
    dto.overdueOnboardingTaskCount = [
      SELECT COUNT()
      FROM Partner_Onboarding_Task__c
      WHERE
        Status__c NOT IN ('Complete', 'Waived', 'Cancelled')
        AND Due_On__c < :currentTime
      WITH USER_MODE
    ];
  }

  private static void addItem(
    InternalDashboardDTO dto,
    Id recordId,
    Id onboardingId,
    String queueType,
    String title,
    String status,
    String priority,
    Datetime dueOn
  ) {
    OnboardingWorkItemDTO item = new OnboardingWorkItemDTO();
    item.recordId = recordId;
    item.onboardingId = onboardingId;
    item.queueType = queueType;
    item.title = title;
    item.status = status;
    item.priority = priority;
    item.dueOn = dueOn;
    dto.onboardingWorkItems.add(item);
  }

  private static void addDealAlert(List<String> alerts, Integer count) {
    if (count <= 0) {
      return;
    }

    alerts.add(
      count +
        (count == 1 ? ' deal registration is' : ' deal registrations are') +
        ' awaiting review.'
    );
  }

  private static void addMdfAlert(List<String> alerts, Integer count) {
    if (count <= 0) {
      return;
    }

    alerts.add(
      count +
        (count == 1 ? ' MDF request is' : ' MDF requests are') +
        ' awaiting review.'
    );
  }

  private static void addNotificationAlert(List<String> alerts, Integer count) {
    if (count <= 0) {
      return;
    }

    alerts.add(
      'You have ' +
        count +
        (count == 1 ? ' unread notification.' : ' unread notifications.')
    );
  }
}
