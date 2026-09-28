/**
 * Executes Deal_Revenue_Attribution__c commands: overrideAttribution,
 * reverseAttribution. The calculated snapshot is never discarded on
 * override (doc §41.22's "persist inputs and result" requirement) - the
 * override just changes the effective percentage/amount alongside it.
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class RevenueAttributionCommandService {
  /**
   * Overrides a calculated attribution's percentage, requiring a reason.
   * The original Calculation_Snapshot__c is preserved untouched.
   *
   * @param command attributionId + expectedVersion + newAttributionPercentage + reason.
   */
  public static void overrideAttribution(RevenueAttributionCommand command) {
    PartnerAccessService.assertInternalUser();
    if (
      !DealLifecyclePermissionService.hasPermission(
        'PartnerSync_Override_Revenue_Attribution'
      )
    ) {
      throw new PartnerSyncHandledException(
        'Current user lacks authority to override revenue attribution.'
      );
    }
    if (String.isBlank(command.reason)) {
      throw new PartnerSyncHandledException(
        'A reason is required to override an attribution.'
      );
    }

    Deal_Revenue_Attribution__c attribution = selectAndCheckVersion(command);
    if (
      attribution.Status__c != 'Calculated' &&
      attribution.Status__c != 'Confirmed'
    ) {
      throw new PartnerSyncHandledException(
        'This attribution is not in a state that can be overridden.'
      );
    }

    if (command.newAttributionPercentage != null) {
      attribution.Attribution_Percentage__c = command.newAttributionPercentage;
    }
    attribution.Override__c = true;
    attribution.Override_Reason__c = command.reason;
    attribution.Status__c = 'Overridden';
    attribution.Approved_By__c = UserInfo.getUserId();
    attribution.Approved_On__c = System.now();
    attribution.Version_Number__c = versionAfter(attribution);
    Database.update(attribution, AccessLevel.SYSTEM_MODE);

    publish(
      'RevenueAttributionOverridden',
      attribution,
      'Revenue attribution was overridden.'
    );
  }

  /**
   * Reverses an attribution row (e.g. following a revenue reversal).
   *
   * @param command attributionId + expectedVersion + reason.
   */
  public static void reverseAttribution(RevenueAttributionCommand command) {
    PartnerAccessService.assertInternalUser();

    Deal_Revenue_Attribution__c attribution = selectAndCheckVersion(command);
    if (attribution.Status__c == 'Reversed') {
      return;
    }
    attribution.Status__c = 'Reversed';
    attribution.Version_Number__c = versionAfter(attribution);
    Database.update(attribution, AccessLevel.SYSTEM_MODE);

    publish(
      'RevenueAttributionReversed',
      attribution,
      'Revenue attribution was reversed.'
    );
  }

  private static Deal_Revenue_Attribution__c selectAndCheckVersion(
    RevenueAttributionCommand command
  ) {
    if (command.attributionId == null) {
      throw new PartnerSyncHandledException(
        'A revenue attribution is required for this command.'
      );
    }
    Deal_Revenue_Attribution__c attribution = RevenueAttributionSelector.selectForUpdate(
      command.attributionId
    );
    Integer version = attribution.Version_Number__c == null
      ? 0
      : Integer.valueOf(attribution.Version_Number__c);
    if (command.expectedVersion == null || command.expectedVersion != version) {
      throw new PartnerSyncHandledException(
        'This attribution changed. Refresh before retrying.'
      );
    }
    return attribution;
  }

  private static Integer versionAfter(Deal_Revenue_Attribution__c attribution) {
    return (attribution.Version_Number__c == null
        ? 0
        : Integer.valueOf(attribution.Version_Number__c)) + 1;
  }

  private static void publish(
    String eventType,
    Deal_Revenue_Attribution__c attribution,
    String message
  ) {
    PlatformEventPublisherService.publish(
      eventType,
      attribution.Deal__c,
      'Deal_Registration__c',
      attribution.Partner_Account__c,
      message,
      'Info'
    );
  }
}
