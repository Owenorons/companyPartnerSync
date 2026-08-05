// Post-deployment application smoke test. Any failed assertion makes the
// Salesforce CLI command fail and stops promotion.
System.assertNotEquals(
    null,
    Tenant_Config__mdt.getInstance('Default'),
    'Required Tenant_Config.Default custom metadata is missing.'
);
System.assert(
    Schema.getGlobalDescribe().containsKey('Deal_Registration__c'),
    'Deal Registration metadata is unavailable.'
);
System.assert(
    Schema.getGlobalDescribe().containsKey('MDF_Request__c'),
    'MDF Request metadata is unavailable.'
);
System.assert(
    Schema.getGlobalDescribe().containsKey('Partner_Record_Share__c'),
    'Partner share registry metadata is unavailable.'
);
System.debug(LoggingLevel.INFO, 'PartnerSync post-deployment smoke test passed.');
