/**
 * Selector layer backing the lead assignment/decision flows: partner
 * account/contact validation queries and Lead reads. Used by
 * LeadDistributionService, LeadDecisionService and LeadConversionService
 * alike — not specific to conversion.
 */
public with sharing class LeadDistributionSelector {
  /**
   * Reads a partner Account, verifying it is a valid, active partner
   * account.
   *
   * @param partnerAccountId Id of the partner Account to read.
   * @return The active partner Account record.
   */
  public static Account selectActivePartnerAccount(Id partnerAccountId) {
    SecurityUtil.assertReadable(Account.SObjectType);

    List<Account> rows = [
      SELECT Id, Is_Partner__c, Partner_Status__c
      FROM Account
      WHERE
        Id = :partnerAccountId
        AND Is_Partner__c = TRUE
        AND Partner_Status__c = 'Active'
      WITH USER_MODE
      LIMIT 1
    ];

    if (rows.isEmpty()) {
      throw new PartnerSyncHandledException(
        'Selected partner account is not active or is not a valid partner account.'
      );
    }

    return rows[0];
  }

  /**
   * Reads a Contact, verifying it belongs to the given partner Account.
   *
   * @param contactId Id of the Contact to read.
   * @param partnerAccountId Id of the partner Account the contact must belong to.
   * @return The partner Contact record.
   */
  public static Contact selectPartnerContact(
    Id contactId,
    Id partnerAccountId
  ) {
    SecurityUtil.assertReadable(Contact.SObjectType);

    List<Contact> rows = [
      SELECT Id, AccountId, Is_Partner_User__c
      FROM Contact
      WHERE Id = :contactId AND AccountId = :partnerAccountId
      WITH USER_MODE
      LIMIT 1
    ];

    if (rows.isEmpty()) {
      throw new PartnerSyncHandledException(
        'Selected contact does not belong to the partner account.'
      );
    }

    return rows[0];
  }

  /**
   * Reads a Lead with the fields needed by the assignment/decision/
   * conversion flows.
   *
   * @param leadId Id of the Lead to read.
   * @return The Lead record with distribution/conversion fields populated.
   */
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

  /**
   * Reads the leads currently visible to a partner in their "My Leads"
   * view (Assigned, Accepted, or Converted; Rejected leads are excluded).
   *
   * @param partnerAccountId Id of the partner Account whose leads to read.
   * @return Up to 200 matching Lead records, most recently assigned first.
   */
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
      // 'Converted' is included deliberately: partners still need to see a
      // lead in "My Leads" after it becomes a deal, not just while it's
      // active. 'Rejected' is excluded — those fall off the partner's view.
      WHERE
        Partner_Account__c = :partnerAccountId
        AND Lead_Distribution_Status__c IN ('Assigned', 'Accepted', 'Converted')
      WITH USER_MODE
      ORDER BY Assigned_Date__c DESC
      LIMIT 200
    ];
  }
}
