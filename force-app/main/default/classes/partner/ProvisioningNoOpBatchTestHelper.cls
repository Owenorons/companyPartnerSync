@IsTest
public class ProvisioningNoOpBatchTestHelper implements Database.Batchable<SObject> {
  public Database.QueryLocator start(Database.BatchableContext context) {
    return Database.getQueryLocator('SELECT Id FROM Account LIMIT 1');
  }

  public void execute(Database.BatchableContext context, List<SObject> scope) {
  }

  public void finish(Database.BatchableContext context) {
  }
}
