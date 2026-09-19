/**
 * Tracks reentrant-safe depth counters marking whether the current transaction is inside a
 * controlled lifecycle mutation or a permissioned lifecycle migration, so other lifecycle code
 * can tell it's running in one of these contexts rather than as a direct, unguarded mutation.
 */
public class DealLifecycleMutationContext {
  private static Integer controlledDepth = 0;
  private static Integer migrationDepth = 0;

  /**
   * Marks entry into a controlled mutation, incrementing the reentrancy depth.
   */
  public static void beginControlledMutation() {
    controlledDepth++;
  }
  /**
   * Marks exit from a controlled mutation, decrementing the reentrancy depth (floored at zero).
   */
  public static void endControlledMutation() {
    controlledDepth = controlledDepth > 0 ? controlledDepth - 1 : 0;
  }
  /**
   * Checks whether the current transaction is inside a controlled mutation.
   *
   * @return True if the controlled mutation depth is greater than zero.
   */
  public static Boolean isControlledMutation() {
    return controlledDepth > 0;
  }

  /**
   * Marks entry into a lifecycle migration, incrementing the reentrancy depth. Requires the
   * running user to hold the 'PartnerSync_Override_Lifecycle' permission.
   */
  public static void beginMigration() {
    if (
      !DealLifecyclePermissionService.hasPermission(
        'PartnerSync_Override_Lifecycle'
      )
    ) {
      throw new DealLifecycleException(
        'Lifecycle migration permission is required.'
      );
    }
    migrationDepth++;
  }
  /**
   * Marks exit from a lifecycle migration, decrementing the reentrancy depth (floored at zero).
   */
  public static void endMigration() {
    migrationDepth = migrationDepth > 0 ? migrationDepth - 1 : 0;
  }
  /**
   * Checks whether the current transaction is inside a lifecycle migration.
   *
   * @return True if the migration depth is greater than zero.
   */
  public static Boolean isMigration() {
    return migrationDepth > 0;
  }
}
