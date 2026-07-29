/*
 * Covers both domain classes for the lead lifecycle in one suite:
 * LeadDistributionDomain (assignment/decision validation, DTO mapping) and
 * LeadConversionDomain (conversion validation, Opportunity building).
 */
@IsTest
private class LeadDomainTest {
  @IsTest
  static void validateAssignmentRequiresLeadId() {
    LeadAssignmentRequestDTO request = new LeadAssignmentRequestDTO();
    request.partnerAccountId = UserInfo.getUserId();

    try {
      LeadDistributionDomain.validateAssignment(request);
      System.assert(false, 'Expected missing lead validation failure.');
    } catch (PartnerSyncHandledException ex) {
      System.assert(
        ex.getMessage().contains('Lead Id'),
        'Unexpected message: ' + ex.getMessage()
      );
    }
  }

  @IsTest
  static void validateDecisionRejectsUnsupportedDecision() {
    LeadDecisionRequestDTO request = new LeadDecisionRequestDTO();
    request.leadId = UserInfo.getUserId();
    request.decision = 'Maybe';

    try {
      LeadDistributionDomain.validateDecision(request);
      System.assert(false, 'Expected unsupported decision validation failure.');
    } catch (PartnerSyncHandledException ex) {
      System.assert(
        ex.getMessage().contains('Unsupported'),
        'Unexpected message: ' + ex.getMessage()
      );
    }
  }

  @IsTest
  static void toDtoMapsLeadFields() {
    Account partner = PartnerSyncTestDataFactory.partnerAccount('Partner');
    insert partner;
    Contact contact = PartnerSyncTestDataFactory.partnerContact(partner.Id);
    insert contact;

    Lead lead = PartnerSyncTestDataFactory.lead(partner.Id, contact.Id);
    insert lead;

    LeadDistributionDTO dto = LeadDistributionDomain.toDTO(lead);

    System.assertEquals(lead.Id, dto.leadId);
    System.assertEquals('Customer Prospect', dto.company);
    System.assertEquals('Assigned', dto.status);
    System.assertNotEquals(null, dto.assignedDate);
  }

  @IsTest
  static void conversionValidateRequiresLeadId() {
    LeadConversionRequestDTO request = new LeadConversionRequestDTO();
    request.opportunityName = 'New Opportunity';
    request.estimatedCloseDate = Date.today().addDays(30);

    try {
      LeadConversionDomain.validate(request);
      System.assert(false, 'Expected missing lead validation failure.');
    } catch (PartnerSyncHandledException ex) {
      System.assert(
        ex.getMessage().contains('Lead Id'),
        'Unexpected message: ' + ex.getMessage()
      );
    }
  }

  @IsTest
  static void conversionValidateRequiresOpportunityName() {
    LeadConversionRequestDTO request = new LeadConversionRequestDTO();
    request.leadId = UserInfo.getUserId();
    request.estimatedCloseDate = Date.today().addDays(30);

    try {
      LeadConversionDomain.validate(request);
      System.assert(
        false,
        'Expected missing opportunity name validation failure.'
      );
    } catch (PartnerSyncHandledException ex) {
      System.assert(
        ex.getMessage().contains('Opportunity name'),
        'Unexpected message: ' + ex.getMessage()
      );
    }
  }

  @IsTest
  static void conversionValidateRequiresEstimatedCloseDate() {
    LeadConversionRequestDTO request = new LeadConversionRequestDTO();
    request.leadId = UserInfo.getUserId();
    request.opportunityName = 'New Opportunity';

    try {
      LeadConversionDomain.validate(request);
      System.assert(false, 'Expected missing close date validation failure.');
    } catch (PartnerSyncHandledException ex) {
      System.assert(
        ex.getMessage().contains('close date'),
        'Unexpected message: ' + ex.getMessage()
      );
    }
  }

  @IsTest
  static void buildOpportunityMapsLeadAndRequestFields() {
    Account partner = PartnerSyncTestDataFactory.partnerAccount('Partner');
    insert partner;
    Contact contact = PartnerSyncTestDataFactory.partnerContact(partner.Id);
    insert contact;

    Lead lead = PartnerSyncTestDataFactory.lead(partner.Id, contact.Id);
    insert lead;

    LeadConversionRequestDTO request = new LeadConversionRequestDTO();
    request.leadId = lead.Id;
    request.opportunityName = 'Acme Expansion';
    request.estimatedValue = 15000;
    request.estimatedCloseDate = Date.today().addDays(45);

    Opportunity opportunity = LeadConversionDomain.buildOpportunity(
      lead,
      partner.Id,
      request
    );

    System.assertEquals('Acme Expansion', opportunity.Name);
    System.assertEquals(partner.Id, opportunity.AccountId);
    System.assertEquals(partner.Id, opportunity.Partner_Account__c);
    System.assertEquals(contact.Id, opportunity.Partner_Contact__c);
    System.assertEquals('Qualification', opportunity.StageName);
    System.assertEquals(15000, opportunity.Amount);
    System.assertEquals('Partner Lead', opportunity.Lead_Source__c);
    System.assertEquals(lead.Id, opportunity.Source_Lead__c);
    System.assertEquals(
      'Pending Registration',
      opportunity.Partner_Deal_Status__c
    );
  }
}
