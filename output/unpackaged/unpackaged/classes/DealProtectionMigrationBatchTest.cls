@IsTest
private class DealProtectionMigrationBatchTest {
  @IsTest
  static void migratesLegacyProtectionAndSkipsCurrentGrant() {
    Deal_Registration__c legacy = new Deal_Registration__c(
      Status__c = 'Approved',
      Protection_Start_Date__c = Date.today().addDays(-5),
      Protection_End_Date__c = Date.today().addDays(25)
    );
    Deal_Registration__c existing = new Deal_Registration__c(
      Status__c = 'Approved',
      Protection_Start_Date__c = Date.today().addDays(-5),
      Protection_End_Date__c = Date.today().addDays(25)
    );
    insert new List<Deal_Registration__c>{ legacy, existing };
    insert new Deal_Protection_Grant__c(
      Deal__c = existing.Id,
      Current__c = true,
      Current_Grant_Key__c = String.valueOf(existing.Id),
      Status__c = 'Active',
      Start_Date__c = existing.Protection_Start_Date__c,
      End_Date__c = existing.Protection_End_Date__c,
      Version_Number__c = 0
    );
    Test.startTest();
    Database.executeBatch(new DealProtectionMigrationBatch(), 100);
    Test.stopTest();
    Assert.areEqual(
      1,
      [SELECT COUNT() FROM Deal_Protection_Grant__c WHERE Deal__c = :legacy.Id]
    );
    Assert.areEqual(
      1,
      [
        SELECT COUNT()
        FROM Deal_Protection_Grant__c
        WHERE Deal__c = :existing.Id
      ]
    );
    Assert.areEqual(
      1,
      [SELECT COUNT() FROM Deal_Protection_Action__c WHERE Deal__c = :legacy.Id]
    );
  }

  @IsTest
  static void migratesTwoHundredLegacyDealsInOneScope() {
    List<Deal_Registration__c> deals = new List<Deal_Registration__c>();
    for (Integer index = 0; index < 200; index++)
      deals.add(
        new Deal_Registration__c(
          Status__c = 'Approved',
          Protection_Start_Date__c = Date.today().addDays(-10),
          Protection_End_Date__c = Date.today().addDays(20)
        )
      );
    insert deals;
    Test.startTest();
    Database.executeBatch(new DealProtectionMigrationBatch(), 200);
    Test.stopTest();
    Set<Id> dealIds = new Map<Id, Deal_Registration__c>(deals).keySet();
    Assert.areEqual(
      200,
      [SELECT COUNT() FROM Deal_Protection_Grant__c WHERE Deal__c IN :dealIds]
    );
    Assert.areEqual(
      200,
      [SELECT COUNT() FROM Deal_Protection_Action__c WHERE Deal__c IN :dealIds]
    );
  }
}
