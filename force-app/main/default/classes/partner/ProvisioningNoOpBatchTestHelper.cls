/**
 * No-op Batchable stub used by provisioning tests to put a real batch job
 * "in flight" (e.g. via Database.executeBatch) without doing any actual
 * work, so reconciler/abort logic has a genuine running job to act on.
 */
@IsTest
public class ProvisioningNoOpBatchTestHelper implements Database.Batchable<SObject> {
  /**
   * Scopes the batch to a single arbitrary Account record.
   *
   * @param context The batch execution context.
   * @return A query locator for one Account record.
   */
  public Database.QueryLocator start(Database.BatchableContext context) {
    return Database.getQueryLocator('SELECT Id FROM Account LIMIT 1');
  }

  /**
   * Does nothing — this batch exists only to occupy a job slot.
   *
   * @param context The batch execution context.
   * @param scope The batch of records for this chunk.
   */
  public void execute(Database.BatchableContext context, List<SObject> scope) {
  }

  /**
   * Does nothing — this batch exists only to occupy a job slot.
   *
   * @param context The batch execution context.
   */
  public void finish(Database.BatchableContext context) {
  }
}
