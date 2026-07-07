public with sharing class LeadDistributionSelector {
  public static Lead selectInternalLead(Id leadId) {
    SecurityUtil.assertReadable(Lead.SObjectType);

    List<Lead> rows = [
      SELECT
        Id,
        Name,
        Company,
        Email,
        Phone,
        Partner_Account__c,
        Partner_Contact__c,
        Customer_Account__c,
        Lead_Distribution_Status__c,
        Assigned_Date__c,
        Accepted_Date__c,
        Rejected_Date__c,
        SLA_Deadline__c,
        Response_SLA_Hours__c,
        Converted_Deal__c
      FROM Lead
      WHERE Id = :leadId
      WITH USER_MODE
      LIMIT 1
    ];

    if (rows.isEmpty()) {
      throw new PartnerSyncHandledException('Lead not found.');
    }

    return rows[0];
  }

  public static Lead selectPartnerLeadById(Id leadId, Id partnerAccountId) {
    SecurityUtil.assertReadable(Lead.SObjectType);

    List<Lead> rows = [
      SELECT
        Id,
        Name,
        Company,
        Email,
        Phone,
        Partner_Account__c,
        Partner_Contact__c,
        Customer_Account__c,
        Lead_Distribution_Status__c,
        Assigned_Date__c,
        Accepted_Date__c,
        Rejected_Date__c,
        SLA_Deadline__c,
        Response_SLA_Hours__c,
        Converted_Deal__c
      FROM Lead
      WHERE Id = :leadId AND Partner_Account__c = :partnerAccountId
      WITH USER_MODE
      LIMIT 1
    ];

    if (rows.isEmpty()) {
      throw new PartnerSyncHandledException(
        'Lead not found or not accessible.'
      );
    }

    return rows[0];
  }

  public static List<Lead> selectAssignedLeadsByPartner(Id partnerAccountId) {
    SecurityUtil.assertReadable(Lead.SObjectType);

    return [
      SELECT
        Id,
        Name,
        Company,
        Email,
        Phone,
        Lead_Distribution_Status__c,
        Assigned_Date__c,
        SLA_Deadline__c,
        Partner_Account__c
      FROM Lead
      WHERE
        Partner_Account__c = :partnerAccountId
        AND Lead_Distribution_Status__c IN ('Assigned', 'Accepted', 'Converted')
      WITH USER_MODE
      ORDER BY Assigned_Date__c DESC
      LIMIT 200
    ];
  }
}
