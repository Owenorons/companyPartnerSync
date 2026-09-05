@IsTest
private class PartnerOnboardingSecurityTest {
  @IsTest
  static void partnerBaseDataIsReadOnlyAndExcludesSensitiveObjects() {
    Set<String> expectedReadOnly = new Set<String>{
      'Partner_Onboarding__c',
      'Partner_Document_Requirement__c',
      'Partner_Document__c',
      'Partner_Agreement__c',
      'Partner_Relationship__c',
      'Partner_Access_Request__c',
      'Partner_Training_Assignment__c'
    };
    Map<String, ObjectPermissions> byObject = new Map<String, ObjectPermissions>();
    for (ObjectPermissions permission : [
      SELECT
        SobjectType,
        PermissionsRead,
        PermissionsCreate,
        PermissionsEdit,
        PermissionsDelete,
        PermissionsModifyAllRecords,
        PermissionsViewAllRecords
      FROM ObjectPermissions
      WHERE Parent.Name = 'PartnerSync_Partner_Base_Data'
    ]) {
      String objectName = permission.SobjectType.replace('psync__', '');
      byObject.put(objectName, permission);
    }
    for (String objectName : expectedReadOnly) {
      System.assert(
        byObject.containsKey(objectName),
        'Missing partner-safe read access for ' + objectName
      );
      ObjectPermissions permission = byObject.get(objectName);
      System.assertEquals(true, permission.PermissionsRead, objectName);
      System.assertEquals(false, permission.PermissionsCreate, objectName);
      System.assertEquals(false, permission.PermissionsEdit, objectName);
      System.assertEquals(false, permission.PermissionsDelete, objectName);
      System.assertEquals(
        false,
        permission.PermissionsModifyAllRecords,
        objectName
      );
      System.assertEquals(
        false,
        permission.PermissionsViewAllRecords,
        objectName
      );
    }
    for (
      String sensitive : new Set<String>{
        'Partner_Document_Review__c',
        'Partner_Assessment__c',
        'Partner_Assessment_Finding__c',
        'Partner_Approval_Plan__c',
        'Partner_Approval_Step__c',
        'Partner_Agreement_Signatory__c',
        'Partner_Signature_Event__c',
        'Partner_Provisioning_Attempt__c',
        'Partner_Lifecycle_Event__c'
      }
    ) {
      System.assert(
        !byObject.containsKey(sensitive) ||
        !byObject.get(sensitive).PermissionsRead,
        'Sensitive object must remain internal-only: ' + sensitive
      );
    }
  }
}
