/**
 * Executes protection-grant lifecycle commands (Activate, Extend, Release, Expire Protection)
 * against Deal_Protection_Grant__c records, idempotently: a prior action row matching the
 * command's key short-circuits re-execution and returns the previously recorded grant.
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class DealProtectionCommandService {
  @TestVisible
  private static Boolean simulateActionInsertFailure = false;

  /**
   * Executes a protection command, dispatching to the matching action (activate, extend,
   * release, or expire) and recording a Deal_Protection_Action__c for idempotency.
   *
   * @param command The protection command to execute.
   * @return The resulting (or unchanged, for a replayed command) Deal_Protection_Grant__c.
   */
  public static Deal_Protection_Grant__c execute(
    DealProtectionCommand command
  ) {
    validate(command);
    List<Deal_Protection_Action__c> prior = [
      SELECT Grant__c
      FROM Deal_Protection_Action__c
      WHERE Command_Key__c = :command.commandKey
      LIMIT 1
    ];
    if (!prior.isEmpty())
      return prior[0].Grant__c == null
        ? null
        : [
            SELECT
              Id,
              Deal__c,
              Status__c,
              Start_Date__c,
              End_Date__c,
              Version_Number__c,
              Current__c,
              Extension_Count__c
            FROM Deal_Protection_Grant__c
            WHERE Id = :prior[0].Grant__c
          ];
    Deal_Registration__c deal = [
      SELECT Id, Status__c, Protection_Start_Date__c, Protection_End_Date__c
      FROM Deal_Registration__c
      WHERE Id = :command.dealId
      FOR UPDATE
    ];

    // The grant/deal mutation below and the idempotency action record are
    // separate DML statements. Callers such as DealExpiryBatch catch and
    // log per-record failures so one bad row doesn't block the rest of a
    // batch, which means an uncaught exception here would NOT roll back
    // whatever already committed (Salesforce only auto-rolls-back when the
    // exception is left uncaught all the way to the transaction boundary).
    // Without this savepoint, a failure on the action-record insert could
    // leave a grant/deal expired, extended, or released with no
    // corresponding Deal_Protection_Action__c row to show for it, silently
    // breaking the idempotency check on any retry.
    Savepoint sp = Database.setSavepoint();
    try {
      Deal_Protection_Grant__c grant;
      if (command.action == 'Activate Protection')
        grant = activate(deal);
      else {
        grant = currentGrant(deal.Id);
        if (
          command.expectedVersion == null ||
          grant.Version_Number__c != command.expectedVersion
        )
          throw new ProtectionCommandException(
            'The protection grant changed. Refresh and retry.'
          );
        if (command.action == 'Extend Protection')
          extend(deal, grant, command);
        else if (command.action == 'Release Protection')
          release(deal, grant, command);
        else if (command.action == 'Expire Protection')
          expire(deal, grant);
        else
          throw new ProtectionCommandException(
            'Unsupported protection action: ' + command.action
          );
      }
      if (Test.isRunningTest() && simulateActionInsertFailure) {
        throw new ProtectionCommandException(
          'Simulated action-insert failure.'
        );
      }
      Database.insert(
        new Deal_Protection_Action__c(
          Deal__c = deal.Id,
          Grant__c = grant.Id,
          Command_Key__c = command.commandKey,
          Action__c = command.action,
          Occurred_On__c = System.now()
        ),
        AccessLevel.SYSTEM_MODE
      );
      return grant;
    } catch (Exception ex) {
      Database.rollback(sp);
      throw ex;
    } finally {
      Database.releaseSavepoint(sp);
    }
  }

  private static Deal_Protection_Grant__c activate(Deal_Registration__c deal) {
    if (
      !new Set<String>{ 'Approved', 'Approved with Conditions' }
        .contains(deal.Status__c)
    )
      throw new ProtectionCommandException(
        'Only an approved deal may receive protection.'
      );
    if (
      [
        SELECT COUNT()
        FROM Deal_Protection_Grant__c
        WHERE Deal__c = :deal.Id AND Current__c = TRUE
      ] > 0
    )
      throw new ProtectionCommandException(
        'The deal already has a current protection grant.'
      );
    List<Approval_Plan__c> plans = [
      SELECT Id, Status__c
      FROM Approval_Plan__c
      WHERE
        Object_Name__c = 'Deal_Registration__c'
        AND Target_Record_Id__c = :deal.Id
        AND Current__c = TRUE
      LIMIT 1
    ];
    if (
      plans.isEmpty() ||
      !new Set<String>{ 'Approved', 'Approved with Conditions' }
        .contains(plans[0].Status__c)
    )
      throw new ProtectionCommandException(
        'A final current approval plan is required.'
      );
    if (
      [
        SELECT COUNT()
        FROM Approval_Condition__c
        WHERE
          Object_Name__c = 'Deal_Registration__c'
          AND Target_Record_Id__c = :deal.Id
          AND Plan__c = :plans[0].Id
          AND Status__c = 'Open'
          AND Condition_Type__c = 'Protection Blocking'
      ] > 0
    )
      throw new ProtectionCommandException(
        'Protection-blocking conditions remain open.'
      );
    Deal_Protection_Policy__mdt policy = policy();
    Date startDate = Date.today();
    Deal_Protection_Grant__c grant = new Deal_Protection_Grant__c(
      Deal__c = deal.Id,
      Approval_Plan__c = plans[0].Id,
      Current__c = true,
      Current_Grant_Key__c = String.valueOf(deal.Id),
      Status__c = 'Active',
      Start_Date__c = startDate,
      End_Date__c = startDate.addDays(Integer.valueOf(policy.Default_Days__c)),
      Version_Number__c = 0,
      Extension_Count__c = 0
    );
    Database.insert(grant, AccessLevel.SYSTEM_MODE);
    syncSummary(deal, grant);
    return grant;
  }

  private static void extend(
    Deal_Registration__c deal,
    Deal_Protection_Grant__c grant,
    DealProtectionCommand command
  ) {
    requireActive(grant);
    Deal_Protection_Policy__mdt policy = policy();
    if (
      command.extensionDays == null ||
      command.extensionDays <= 0 ||
      command.extensionDays > policy.Maximum_Extension_Days__c ||
      grant.Extension_Count__c >= policy.Maximum_Extensions__c ||
      String.isBlank(command.reason)
    )
      throw new ProtectionCommandException(
        'Extension days, reason, and policy limits must be satisfied.'
      );
    grant.End_Date__c = grant.End_Date__c.addDays(command.extensionDays);
    grant.Extension_Count__c++;
    grant.Version_Number__c++;
    Database.update(grant, AccessLevel.SYSTEM_MODE);
    Database.insert(
      new Deal_Protection_Extension__c(
        Grant__c = grant.Id,
        Days__c = command.extensionDays,
        Reason__c = command.reason,
        Status__c = 'Approved',
        Requested_On__c = System.now()
      ),
      AccessLevel.SYSTEM_MODE
    );
    syncSummary(deal, grant);
  }

  private static void release(
    Deal_Registration__c deal,
    Deal_Protection_Grant__c grant,
    DealProtectionCommand command
  ) {
    requireActive(grant);
    if (String.isBlank(command.reason))
      throw new ProtectionCommandException('A release reason is required.');
    grant.Status__c = 'Released';
    grant.Current__c = false;
    grant.Current_Grant_Key__c = null;
    grant.Release_Reason__c = command.reason;
    grant.Released_On__c = System.now();
    grant.Version_Number__c++;
    Database.update(grant, AccessLevel.SYSTEM_MODE);
    deal.Protection_Start_Date__c = null;
    deal.Protection_End_Date__c = null;
    Database.update(deal, AccessLevel.SYSTEM_MODE);
  }

  private static void expire(
    Deal_Registration__c deal,
    Deal_Protection_Grant__c grant
  ) {
    requireActive(grant);
    if (grant.End_Date__c == null || grant.End_Date__c >= Date.today())
      throw new ProtectionCommandException(
        'The protection grant has not expired.'
      );
    grant.Status__c = 'Expired';
    grant.Current__c = false;
    grant.Current_Grant_Key__c = null;
    grant.Version_Number__c++;
    Database.update(grant, AccessLevel.SYSTEM_MODE);
    deal.Status__c = 'Expired';
    Database.update(deal, AccessLevel.SYSTEM_MODE);
  }

  private static Deal_Protection_Grant__c currentGrant(Id dealId) {
    List<Deal_Protection_Grant__c> grants = [
      SELECT
        Id,
        Deal__c,
        Status__c,
        Start_Date__c,
        End_Date__c,
        Version_Number__c,
        Current__c,
        Extension_Count__c
      FROM Deal_Protection_Grant__c
      WHERE Deal__c = :dealId AND Current__c = TRUE
      FOR UPDATE
    ];
    if (grants.size() != 1)
      throw new ProtectionCommandException(
        'Exactly one current protection grant is required.'
      );
    return grants[0];
  }
  private static void syncSummary(
    Deal_Registration__c deal,
    Deal_Protection_Grant__c grant
  ) {
    deal.Protection_Start_Date__c = grant.Start_Date__c;
    deal.Protection_End_Date__c = grant.End_Date__c;
    Database.update(deal, AccessLevel.SYSTEM_MODE);
  }
  private static Deal_Protection_Policy__mdt policy() {
    List<Deal_Protection_Policy__mdt> policies = [
      SELECT Default_Days__c, Maximum_Extension_Days__c, Maximum_Extensions__c
      FROM Deal_Protection_Policy__mdt
      WHERE Active__c = TRUE
      WITH USER_MODE
      LIMIT 1
    ];
    if (policies.isEmpty())
      throw new ProtectionCommandException(
        'No active protection policy exists.'
      );
    return policies[0];
  }
  private static void requireActive(Deal_Protection_Grant__c grant) {
    if (grant.Status__c != 'Active')
      throw new ProtectionCommandException('Protection is not active.');
  }
  private static void validate(DealProtectionCommand command) {
    if (
      command == null ||
      command.dealId == null ||
      String.isBlank(command.action) ||
      String.isBlank(command.commandKey) ||
      command.commandKey.length() > 80
    )
      throw new ProtectionCommandException(
        'Deal, action, and a command key are required.'
      );
  }
  /**
   * Thrown when a protection command can't be executed, e.g. a stale version, an inactive grant,
   * an unapproved deal, or a policy limit being exceeded.
   */
  public class ProtectionCommandException extends Exception {
  }
}
