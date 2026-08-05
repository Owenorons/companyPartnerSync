/*
 * PartnerSync: assign the running user full internal-administrator access.
 *
 * Being a System Administrator does NOT automatically grant any PartnerSync
 * access. This script assigns PSG_Internal_Administrator, the single source of
 * truth for the complete internal-admin bundle.
 *
 * PermissionService recognizes component permission sets inherited through an
 * assigned permission-set group, so PartnerPermissionService checks continue
 * to work without redundant direct assignments.
 *
 * Run via Execute Anonymous (VS Code: right-click this file > "Execute
 * Anonymous Apex", or `sf apex run --file
 * scripts/apex/assign-internal-admin-access.apex --target-org <alias>`).
 *
 * Safe to re-run: skips the group if it is already assigned. The script fails
 * before DML when the running user is not an active internal user or the
 * permission-set group is unavailable.
 */

Id runningUserId = UserInfo.getUserId();
String permissionSetGroupName = 'PSG_Internal_Administrator';
String packageNamespace = 'psync';

User runningUser = [
  SELECT Id, IsActive, UserType, Username
  FROM User
  WHERE Id = :runningUserId
];

if (!runningUser.IsActive || runningUser.UserType != 'Standard') {
  throw new IllegalArgumentException(
    'PSG_Internal_Administrator can only be assigned to an active internal user.'
  );
}

List<PermissionSetGroup> candidates = [
  SELECT Id, DeveloperName, NamespacePrefix
  FROM PermissionSetGroup
  WHERE
    DeveloperName = :permissionSetGroupName
    AND (NamespacePrefix = :packageNamespace
    OR NamespacePrefix = NULL)
  ORDER BY NamespacePrefix DESC NULLS LAST
];

if (candidates.isEmpty()) {
  throw new IllegalArgumentException(
    permissionSetGroupName +
    ' was not found. Deploy the PartnerSync permission-set-group metadata first.'
  );
}

PermissionSetGroup adminGroup = candidates[0];

List<PermissionSetAssignment> existingAssignments = [
  SELECT Id
  FROM PermissionSetAssignment
  WHERE AssigneeId = :runningUserId AND PermissionSetGroupId = :adminGroup.Id
  LIMIT 1
];

if (existingAssignments.isEmpty()) {
  try {
    insert new PermissionSetAssignment(
      AssigneeId = runningUserId,
      PermissionSetGroupId = adminGroup.Id
    );
  } catch (DmlException ex) {
    throw new IllegalArgumentException(
      'Could not assign ' +
        permissionSetGroupName +
        ' to ' +
        runningUser.Username +
        ': ' +
        ex.getDmlMessage(0)
    );
  }

  System.debug(
    '=== Assigned ' +
      permissionSetGroupName +
      ' to ' +
      runningUser.Username +
      ' ==='
  );
} else {
  System.debug(
    '=== ' +
      permissionSetGroupName +
      ' is already assigned to ' +
      runningUser.Username +
      ' ==='
  );
}
