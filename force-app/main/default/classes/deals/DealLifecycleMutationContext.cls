public class DealLifecycleMutationContext {
  private static Integer controlledDepth = 0;
  private static Integer migrationDepth = 0;

  public static void beginControlledMutation() {
    controlledDepth++;
  }
  public static void endControlledMutation() {
    controlledDepth = controlledDepth > 0 ? controlledDepth - 1 : 0;
  }
  public static Boolean isControlledMutation() {
    return controlledDepth > 0;
  }

  public static void beginMigration() {
    if (!FeatureManagement.checkPermission('PartnerSync_Override_Lifecycle')) {
      throw new DealLifecycleException(
        'Lifecycle migration permission is required.'
      );
    }
    migrationDepth++;
  }
  public static void endMigration() {
    migrationDepth = migrationDepth > 0 ? migrationDepth - 1 : 0;
  }
  public static Boolean isMigration() {
    return migrationDepth > 0;
  }
}
