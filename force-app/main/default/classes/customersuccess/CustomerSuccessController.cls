/**
 * Aura controller surface for Sprint 42: the partner-facing customer
 * success/renewal summary (partnerCustomerSuccessWorkspace) and the
 * internal Customer Success Workbench's queue views
 * (customerSuccessWorkbench). Pure pass-through/exception-translation
 * layer over the customersuccess/ command services and selectors - no
 * business logic here, mirroring RevenueController's shape.
 */
public with sharing class CustomerSuccessController {
  /**
   * Loads the current partner's customer success engagements.
   *
   * @return The current partner's partner-safe engagement summaries.
   */
  @AuraEnabled(cacheable=true)
  public static List<CustomerSuccessSummaryDTO> getMyEngagements() {
    try {
      if (
        !PartnerAccessService.isInternalUser() &&
        !DealLifecyclePermissionService.hasPermission(
          'PartnerSync_View_Customer_Success'
        )
      ) {
        throw new PartnerSyncHandledException(
          'Current user lacks authority to view customer success engagements.'
        );
      }

      Id currentPartnerAccountId = PartnerAccessService.isInternalUser()
        ? null
        : PartnerAccessService.getCurrentPartnerAccountId();

      List<CustomerSuccessSummaryDTO> results = new List<CustomerSuccessSummaryDTO>();
      List<Customer_Success_Engagement__c> rows = currentPartnerAccountId ==
        null
        ? [
            SELECT
              Id,
              Customer_Account__c,
              Status__c,
              Health_Status__c,
              Health_Score__c,
              Primary_Partner__c,
              Current_Renewal__c
            FROM Customer_Success_Engagement__c
            WITH SYSTEM_MODE
            ORDER BY CreatedDate DESC
            LIMIT 200
          ]
        : [
            SELECT
              Id,
              Customer_Account__c,
              Status__c,
              Health_Status__c,
              Health_Score__c,
              Primary_Partner__c,
              Current_Renewal__c
            FROM Customer_Success_Engagement__c
            WHERE Primary_Partner__c = :currentPartnerAccountId
            WITH SYSTEM_MODE
            ORDER BY CreatedDate DESC
            LIMIT 200
          ];
      for (Customer_Success_Engagement__c engagement : rows) {
        results.add(toSummaryDTO(engagement));
      }
      return results;
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'CustomerSuccessController',
        'Unable to load customer success engagements.',
        'Unable to load customer success engagements.',
        ex
      );
    }
  }

  /**
   * Loads the current partner's renewals.
   *
   * @return The current partner's partner-safe renewal summaries.
   */
  @AuraEnabled(cacheable=true)
  public static List<RenewalSummaryDTO> getMyRenewals() {
    try {
      if (
        !PartnerAccessService.isInternalUser() &&
        !DealLifecyclePermissionService.hasPermission(
          'PartnerSync_View_Renewal'
        )
      ) {
        throw new PartnerSyncHandledException(
          'Current user lacks authority to view renewals.'
        );
      }

      Id currentPartnerAccountId = PartnerAccessService.isInternalUser()
        ? null
        : PartnerAccessService.getCurrentPartnerAccountId();

      List<RenewalSummaryDTO> results = new List<RenewalSummaryDTO>();
      List<Partner_Renewal__c> rows = currentPartnerAccountId == null
        ? [
            SELECT
              Id,
              Customer_Success_Engagement__c,
              Status__c,
              Renewal_Health__c,
              Target_Decision_On__c,
              Primary_Partner__c,
              Version_Number__c
            FROM Partner_Renewal__c
            WITH SYSTEM_MODE
            ORDER BY Target_Decision_On__c ASC NULLS LAST
            LIMIT 200
          ]
        : [
            SELECT
              Id,
              Customer_Success_Engagement__c,
              Status__c,
              Renewal_Health__c,
              Target_Decision_On__c,
              Primary_Partner__c,
              Version_Number__c
            FROM Partner_Renewal__c
            WHERE Primary_Partner__c = :currentPartnerAccountId
            WITH SYSTEM_MODE
            ORDER BY Target_Decision_On__c ASC NULLS LAST
            LIMIT 200
          ];
      for (Partner_Renewal__c renewal : rows) {
        results.add(toSummaryDTO(renewal));
      }
      return results;
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'CustomerSuccessController',
        'Unable to load renewals.',
        'Unable to load renewals.',
        ex
      );
    }
  }

  /**
   * Confirms the current partner's continued participation in a renewal.
   *
   * @param command renewalId + expectedVersion.
   * @return The updated renewal.
   */
  @AuraEnabled
  public static RenewalSummaryDTO confirmRenewal(RenewalCommand command) {
    try {
      return toSummaryDTO(RenewalCommandService.confirmParticipation(command));
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'CustomerSuccessController',
        'Unable to confirm the renewal.',
        'Unable to confirm the renewal.',
        ex
      );
    }
  }

  /**
   * Declines the current partner's continued participation in a renewal.
   *
   * @param command renewalId + expectedVersion + reason.
   * @return The updated renewal.
   */
  @AuraEnabled
  public static RenewalSummaryDTO declineRenewal(RenewalCommand command) {
    try {
      return toSummaryDTO(RenewalCommandService.declineParticipation(command));
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'CustomerSuccessController',
        'Unable to decline the renewal.',
        'Unable to decline the renewal.',
        ex
      );
    }
  }

  /**
   * Loads engagements awaiting handoff acceptance, for the Customer
   * Success Workbench's "Pending Handoff" queue tab.
   *
   * @return Up to 200 such rows.
   */
  @AuraEnabled(cacheable=true)
  public static List<Customer_Success_Engagement__c> getPendingHandoffs() {
    try {
      PartnerAccessService.assertInternalUser();
      return [
        SELECT Id, Customer_Account__c, Primary_Partner__c, Handoff_Snapshot__c
        FROM Customer_Success_Engagement__c
        WHERE Status__c = 'Pending Handoff'
        WITH SYSTEM_MODE
        ORDER BY CreatedDate ASC
        LIMIT 200
      ];
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'CustomerSuccessController',
        'Unable to load pending handoffs.',
        'Unable to load pending handoffs.',
        ex
      );
    }
  }

  /**
   * Loads engagements at At Risk or Critical health, for the Customer
   * Success Workbench's "At Risk / Critical" queue tab.
   *
   * @return Up to 200 such rows.
   */
  @AuraEnabled(cacheable=true)
  public static List<Customer_Success_Engagement__c> getAtRiskEngagements() {
    try {
      PartnerAccessService.assertInternalUser();
      return [
        SELECT Id, Customer_Account__c, Health_Status__c, Health_Score__c
        FROM Customer_Success_Engagement__c
        WHERE Health_Status__c IN ('At Risk', 'Critical')
        WITH SYSTEM_MODE
        ORDER BY Health_Score__c ASC NULLS LAST
        LIMIT 200
      ];
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'CustomerSuccessController',
        'Unable to load at-risk engagements.',
        'Unable to load at-risk engagements.',
        ex
      );
    }
  }

  /**
   * Loads renewals awaiting internal qualification/review/approval, for
   * the Customer Success Workbench's "Renewals Due" queue tab.
   *
   * @return Up to 200 such rows.
   */
  @AuraEnabled(cacheable=true)
  public static List<Partner_Renewal__c> getRenewalsDue() {
    try {
      PartnerAccessService.assertInternalUser();
      return [
        SELECT Id, Customer_Account__c, Status__c, Target_Decision_On__c
        FROM Partner_Renewal__c
        WHERE
          Status__c IN ('Partner Confirmed', 'Qualification', 'Review Required')
        WITH SYSTEM_MODE
        ORDER BY Target_Decision_On__c ASC NULLS LAST
        LIMIT 200
      ];
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'CustomerSuccessController',
        'Unable to load renewals due.',
        'Unable to load renewals due.',
        ex
      );
    }
  }

  /**
   * Loads renewals awaiting partner confirmation, for the Customer
   * Success Workbench's "Partner Confirmation Required" queue tab.
   *
   * @return Up to 200 such rows.
   */
  @AuraEnabled(cacheable=true)
  public static List<Partner_Renewal__c> getPartnerConfirmationRequired() {
    try {
      PartnerAccessService.assertInternalUser();
      return [
        SELECT
          Id,
          Customer_Account__c,
          Primary_Partner__c,
          Target_Decision_On__c
        FROM Partner_Renewal__c
        WHERE Status__c = 'Partner Confirmation Required'
        WITH SYSTEM_MODE
        ORDER BY Target_Decision_On__c ASC NULLS LAST
        LIMIT 200
      ];
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'CustomerSuccessController',
        'Unable to load renewals awaiting partner confirmation.',
        'Unable to load renewals awaiting partner confirmation.',
        ex
      );
    }
  }

  /**
   * Loads open expansion opportunities, for the Customer Success
   * Workbench's "Expansion Opportunities" queue tab.
   *
   * @return Up to 200 such rows.
   */
  @AuraEnabled(cacheable=true)
  public static List<Partner_Expansion__c> getExpansionOpportunities() {
    try {
      PartnerAccessService.assertInternalUser();
      return [
        SELECT Id, Customer_Account__c, Expansion_Type__c, Status__c
        FROM Partner_Expansion__c
        WHERE Status__c NOT IN ('Completed', 'Cancelled')
        WITH SYSTEM_MODE
        ORDER BY CreatedDate ASC
        LIMIT 200
      ];
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'CustomerSuccessController',
        'Unable to load expansion opportunities.',
        'Unable to load expansion opportunities.',
        ex
      );
    }
  }

  /**
   * Loads reassignment requests awaiting approval, for the Customer
   * Success Workbench's "Partner Reassignment" queue tab.
   *
   * @return Up to 200 such rows.
   */
  @AuraEnabled(cacheable=true)
  public static List<Partner_Reassignment__c> getPendingReassignments() {
    try {
      PartnerAccessService.assertInternalUser();
      return [
        SELECT
          Id,
          Target_Object__c,
          Current_Partner__c,
          Requested_Partner__c,
          Reason__c
        FROM Partner_Reassignment__c
        WHERE Status__c = 'Requested'
        WITH SYSTEM_MODE
        ORDER BY CreatedDate ASC
        LIMIT 200
      ];
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'CustomerSuccessController',
        'Unable to load pending partner reassignments.',
        'Unable to load pending partner reassignments.',
        ex
      );
    }
  }

  /**
   * Loads churned engagements, for the Customer Success Workbench's
   * "Churn" queue tab.
   *
   * @return Up to 200 such rows.
   */
  @AuraEnabled(cacheable=true)
  public static List<Customer_Success_Engagement__c> getChurnedEngagements() {
    try {
      PartnerAccessService.assertInternalUser();
      return [
        SELECT
          Id,
          Customer_Account__c,
          Churned_On__c,
          Churn_Category__c,
          Churn_Reason__c
        FROM Customer_Success_Engagement__c
        WHERE Status__c = 'Churned'
        WITH SYSTEM_MODE
        ORDER BY Churned_On__c DESC
        LIMIT 200
      ];
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'CustomerSuccessController',
        'Unable to load churned engagements.',
        'Unable to load churned engagements.',
        ex
      );
    }
  }

  private static CustomerSuccessSummaryDTO toSummaryDTO(
    Customer_Success_Engagement__c engagement
  ) {
    CustomerSuccessSummaryDTO dto = new CustomerSuccessSummaryDTO();
    dto.engagementId = engagement.Id;
    dto.customerAccountId = engagement.Customer_Account__c;
    dto.status = engagement.Status__c;
    dto.healthStatus = engagement.Health_Status__c;
    dto.healthScore = engagement.Health_Score__c;
    dto.primaryPartnerId = engagement.Primary_Partner__c;
    dto.currentRenewalId = engagement.Current_Renewal__c;
    return dto;
  }

  private static RenewalSummaryDTO toSummaryDTO(Partner_Renewal__c renewal) {
    RenewalSummaryDTO dto = new RenewalSummaryDTO();
    dto.renewalId = renewal.Id;
    dto.engagementId = renewal.Customer_Success_Engagement__c;
    dto.status = renewal.Status__c;
    dto.renewalHealth = renewal.Renewal_Health__c;
    dto.targetDecisionOn = renewal.Target_Decision_On__c;
    dto.primaryPartnerId = renewal.Primary_Partner__c;
    dto.versionNumber = renewal.Version_Number__c == null
      ? 0
      : Integer.valueOf(renewal.Version_Number__c);
    return dto;
  }
}
