public class DealLifecyclePermissionService {
  @TestVisible
  private static Map<String, Boolean> testOverrides = new Map<String, Boolean>();

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
