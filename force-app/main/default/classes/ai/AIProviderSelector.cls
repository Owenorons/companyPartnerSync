/*
 * Selector layer for the AI provider catalog (AI_Provider_Config__mdt)
 * and connection status (AI_Configuration__c).
 */
public with sharing class AIProviderSelector {
  public static List<AI_Provider_Config__mdt> selectAllProviders() {
    return [
      SELECT DeveloperName, Provider_Name__c, Provider_Type__c, Active__c
      FROM AI_Provider_Config__mdt
      WITH USER_MODE
      ORDER BY Provider_Name__c ASC
    ];
  }

  public static Map<String, AI_Configuration__c> selectStatusByProvider() {
    SecurityUtil.assertReadable(AI_Configuration__c.SObjectType);

    Map<String, AI_Configuration__c> statusByProvider = new Map<String, AI_Configuration__c>();

    List<AI_Configuration__c> statuses = [
      SELECT
        Provider__c,
        Connection_Status__c,
        Last_Test_Date__c,
        Last_Test_Result__c
      FROM AI_Configuration__c
      WITH USER_MODE
    ];

    for (AI_Configuration__c status : statuses) {
      statusByProvider.put(status.Provider__c, status);
    }

    return statusByProvider;
  }
}
