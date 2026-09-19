// Subscriber-safe post-install smoke test. Dynamic names avoid compile-time
// coupling to whether this script runs inside the namespace org or in an org
// where PartnerSync is installed as a managed package.
Map<String, Schema.SObjectType> availableTypes = Schema.getGlobalDescribe();
String namespacePrefix = availableTypes.containsKey(
    'psync__Deal_Registration__c'
  )
  ? 'psync__'
  : '';

for (
  String objectName : new List<String>{
    'Deal_Registration__c',
    'MDF_Request__c',
    'Partner_Record_Share__c'
  }
) {
  System.assert(
    availableTypes.containsKey(namespacePrefix + objectName),
    objectName + ' metadata is unavailable.'
  );
}

String tenantConfigType = namespacePrefix + 'Tenant_Config__mdt';
System.assert(
  availableTypes.containsKey(tenantConfigType),
  'Tenant_Config__mdt metadata is unavailable.'
);
List<SObject> tenantConfigs = Database.query(
  'SELECT DeveloperName FROM ' +
    tenantConfigType +
    ' WHERE DeveloperName = \'Default\' LIMIT 1'
);
System.assertEquals(
  1,
  tenantConfigs.size(),
  'Required Tenant_Config.Default custom metadata is missing.'
);
System.debug(
  LoggingLevel.INFO,
  'PartnerSync post-install smoke test passed for namespace prefix: ' +
  namespacePrefix
);
