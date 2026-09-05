public without sharing class DealValidationFindingService {
  @SuppressWarnings('PMD.ApexCRUDViolation')
  public static void replaceCurrent(
    Id dealId,
    List<DealValidationFinding> findings
  ) {
    List<Deal_Validation_Finding__c> prior = [
      SELECT Id, Status__c
      FROM Deal_Validation_Finding__c
      WHERE Deal__c = :dealId AND Status__c = 'Current'
    ];
    for (Deal_Validation_Finding__c row : prior) {
      row.Status__c = 'Superseded';
    }
    if (!prior.isEmpty()) {
      Database.update(prior, AccessLevel.SYSTEM_MODE);
    }

    List<Deal_Validation_Finding__c> rows = new List<Deal_Validation_Finding__c>();
    for (DealValidationFinding finding : findings) {
      rows.add(
        new Deal_Validation_Finding__c(
          Deal__c = dealId,
          Rule_Key__c = finding.ruleKey,
          Rule_Version__c = finding.ruleVersion,
          Category__c = finding.category,
          Severity__c = finding.severity,
          Blocking__c = finding.blocking,
          Internal_Message__c = finding.internalMessage,
          Partner_Message__c = finding.partnerMessage,
          Field_Reference__c = finding.fieldReference,
          Remediation__c = finding.remediation,
          Status__c = 'Current'
        )
      );
    }
    if (!rows.isEmpty()) {
      Database.insert(rows, AccessLevel.SYSTEM_MODE);
    }
  }
}
