/*
 * Low-level permission-set/permission-set-group membership checks. This is
 * the generic building block underneath business-specific gates like
 * PartnerPermissionService — it only answers "does the running user have
 * this permission set/group," with no knowledge of what any particular
 * permission set is meant to authorize.
 */
public with sharing class PermissionService {
  public static Boolean hasPermissionSet(String permissionSetName) {
    return hasAnyPermissionSet(new List<String>{ permissionSetName });
  }

  public static Boolean hasAnyPermissionSet(List<String> permissionSetNames) {
    if (permissionSetNames == null || permissionSetNames.isEmpty()) {
      return false;
    }

    // A permission set can reach a user either by direct assignment or via
    // a permission set group the user belongs to — checking assignments
    // alone would miss anyone granted access only through group membership.
    List<PermissionSetAssignment> directAssignments = [
      SELECT Id
      FROM PermissionSetAssignment
      WHERE
        AssigneeId = :UserInfo.getUserId()
        AND PermissionSet.Name IN :permissionSetNames
      WITH USER_MODE
      LIMIT 1
    ];

    if (!directAssignments.isEmpty()) {
      return true;
    }

    Set<Id> assignedGroupIds = new Set<Id>();
    for (PermissionSetAssignment assignment : [
      SELECT PermissionSetGroupId
      FROM PermissionSetAssignment
      WHERE AssigneeId = :UserInfo.getUserId() AND PermissionSetGroupId != NULL
      WITH USER_MODE
    ]) {
      assignedGroupIds.add(assignment.PermissionSetGroupId);
    }

    if (assignedGroupIds.isEmpty()) {
      return false;
    }

    List<PermissionSetGroupComponent> inheritedPermissions = [
      SELECT Id
      FROM PermissionSetGroupComponent
      WHERE
        PermissionSetGroupId IN :assignedGroupIds
        AND PermissionSet.Name IN :permissionSetNames
      WITH USER_MODE
      LIMIT 1
    ];

    return !inheritedPermissions.isEmpty();
  }

  public static Boolean hasCustomPermission(String customPermissionName) {
    if (String.isBlank(customPermissionName)) {
      return false;
    }

    return FeatureManagement.checkPermission(customPermissionName);
  }

  public static Boolean hasPermissionGroup(String permissionSetGroupName) {
    if (String.isBlank(permissionSetGroupName)) {
      return false;
    }

    List<PermissionSetAssignment> assignments = [
      SELECT Id
      FROM PermissionSetAssignment
      WHERE
        AssigneeId = :UserInfo.getUserId()
        AND PermissionSetGroup.DeveloperName = :permissionSetGroupName
      WITH USER_MODE
      LIMIT 1
    ];

    return !assignments.isEmpty();
  }
}
