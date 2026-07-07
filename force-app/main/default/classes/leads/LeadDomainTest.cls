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
}
