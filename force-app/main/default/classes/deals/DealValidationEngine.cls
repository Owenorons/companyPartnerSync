@SuppressWarnings('PMD.ApexSOQLInjection')
public without sharing class DealValidationEngine {
  public static List<DealValidationFinding> evaluate(
    Deal_Registration__c deal
  ) {
    String suffix = 'Deal_Validation_Rule__mdt';
    String objectApiName = resolveObjectApiName(suffix);
    String prefix = objectApiName.substring(
      0,
      objectApiName.length() - suffix.length()
    );
    String query =
      'SELECT DeveloperName, ' +
      prefixedFields(prefix) +
      ' FROM ' +
      objectApiName +
      ' WHERE ' +
      prefix +
      'Active__c = TRUE ORDER BY DeveloperName';

    List<DealValidationFinding> findings = new List<DealValidationFinding>();
    for (SObject rule : Database.query(query, AccessLevel.SYSTEM_MODE)) {
      if (fails(rule, prefix, deal)) {
        DealValidationFinding finding = new DealValidationFinding();
        finding.ruleKey = (String) rule.get('DeveloperName');
        finding.ruleVersion = (String) rule.get(prefix + 'Rule_Version__c');
        finding.category = (String) rule.get(prefix + 'Category__c');
        finding.severity = (String) rule.get(prefix + 'Severity__c');
        finding.blocking = (Boolean) rule.get(prefix + 'Blocking__c');
        finding.internalMessage = (String) rule.get(
          prefix + 'Internal_Message__c'
        );
        finding.partnerMessage = (String) rule.get(
          prefix + 'Partner_Message__c'
        );
        finding.fieldReference = (String) rule.get(prefix + 'Target_Field__c');
        finding.remediation = (String) rule.get(prefix + 'Remediation__c');
        findings.add(finding);
      }
    }
    return findings;
  }

  private static Boolean fails(
    SObject rule,
    String prefix,
    Deal_Registration__c deal
  ) {
    if ((String) rule.get(prefix + 'Operator__c') != 'Required') {
      return false;
    }
    Object value = deal.get((String) rule.get(prefix + 'Target_Field__c'));
    return value == null ||
      (value instanceof String && String.isBlank((String) value));
  }

  private static String resolveObjectApiName(String suffix) {
    for (String apiName : Schema.getGlobalDescribe().keySet()) {
      if (apiName.toLowerCase().endsWith(suffix.toLowerCase())) {
        return apiName;
      }
    }
    throw new DealLifecycleException(
      'Deal validation rule metadata is not installed.'
    );
  }

  private static String prefixedFields(String prefix) {
    List<String> names = new List<String>{
      'Rule_Version__c',
      'Category__c',
      'Severity__c',
      'Blocking__c',
      'Target_Field__c',
      'Operator__c',
      'Internal_Message__c',
      'Partner_Message__c',
      'Remediation__c'
    };
    for (Integer index = 0; index < names.size(); index++) {
      names[index] = prefix + names[index];
    }
    return String.join(names, ', ');
  }
}
