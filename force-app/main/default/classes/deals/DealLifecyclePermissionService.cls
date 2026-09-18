/**
 * Resolves whether the running user holds a named custom permission,
 * supporting test-time overrides of the underlying FeatureManagement check.
 */
public class DealLifecyclePermissionService {
  @TestVisible
  private static Map<String, Boolean> testOverrides = new Map<String, Boolean>();

  /**
   * Determines whether the running user has the given custom permission. A
   * blank permission name is treated as always allowed. During tests, a
   * value set via setTestPermission takes precedence over the real check.
   *
   * @param permissionName Developer name of the custom permission to check.
   * @return True if the permission is granted (or the name is blank); false otherwise.
   */
  public static Boolean hasPermission(String permissionName) {
    if (String.isBlank(permissionName)) {
      return true;
    }
    if (Test.isRunningTest() && testOverrides.containsKey(permissionName)) {
      return testOverrides.get(permissionName);
    }
    return FeatureManagement.checkPermission(permissionName);
  }

  @TestVisible
  private static void setTestPermission(
    String permissionName,
    Boolean allowed
  ) {
    testOverrides.put(permissionName, allowed);
  }

  @TestVisible
  private static void clearTestPermissions() {
    testOverrides.clear();
  }
}
