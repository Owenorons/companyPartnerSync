/**
 * Write-only cross-feature usage ledger. Appends one Usage_Metric__c row per
 * billable partner activity (AI Request, Deal Submitted, MDF Request, Lead
 * Assigned, Content Download, Notification Sent). Modeled on
 * NotificationService.create(): a SYSTEM_MODE insert wrapped in try/catch,
 * so metering can never fail or block the real business transaction it's
 * attached to. Partner users have zero permission-set access to
 * Usage_Metric__c, so SYSTEM_MODE (not USER_MODE/CRUD-gated, unlike
 * PartnerContentService.logUsage()) is required for every one of the six
 * call sites to actually write a row rather than silently no-op.
 */
public with sharing class UsageMetricService {
  /** Metric type constant for a billable AI request. */
  public static final String METRIC_TYPE_AI_REQUEST = 'AI Request';
  /** Metric type constant for a submitted deal registration. */
  public static final String METRIC_TYPE_DEAL_SUBMITTED = 'Deal Submitted';
  /** Metric type constant for a submitted MDF request. */
  public static final String METRIC_TYPE_MDF_REQUEST = 'MDF Request';
  /** Metric type constant for a lead assignment. */
  public static final String METRIC_TYPE_LEAD_ASSIGNED = 'Lead Assigned';
  /** Metric type constant for a content download. */
  public static final String METRIC_TYPE_CONTENT_DOWNLOAD = 'Content Download';
  /** Metric type constant for a delivered notification. */
  public static final String METRIC_TYPE_NOTIFICATION_SENT = 'Notification Sent';

  /**
   * Appends a single Usage_Metric__c row for a billable partner activity.
   * Runs in system mode and swallows any failure (logging a warning
   * instead), so metering can never fail or block the business transaction
   * it's attached to.
   *
   * @param partnerAccountId The partner account the usage is attributed to.
   * @param metricType The type of activity being metered; one of the METRIC_TYPE_* constants.
   */
  public static void log(Id partnerAccountId, String metricType) {
    try {
      Usage_Metric__c metric = new Usage_Metric__c();
      metric.Partner_Account__c = partnerAccountId;
      metric.Metric_Type__c = metricType;
      metric.Metric_Date__c = Date.today();
      metric.Quantity__c = 1;
      metric.License_Tier__c = TenantConfigService.getEdition();
      Database.insert(metric, AccessLevel.SYSTEM_MODE);
    } catch (Exception ex) {
      LoggingService.warn(
        'UsageMetricService',
        'Failed to log usage metric: ' + metricType + ' - ' + ex.getMessage()
      );
    }
  }
}
