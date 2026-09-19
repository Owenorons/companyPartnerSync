/*
 * Coverage for PermissionService's membership checks: direct permission-set
 * assignment, group-inherited assignment, custom permissions, and the
 * null/empty/unassigned negative cases for each.
 */
@IsTest
private class PermissionServiceTest {
  @IsTest
  static void hasPermissionSetTrueWhenAssignedFalseWhenNot() {
    User assignedUser = TestUserFactory.createInternalUser();
    User unassignedUser = TestUserFactory.createInternalUser();

    TestUserFactory.assignPermissionSet(
      assignedUser.Id,
      'PartnerSync_Internal_Admin'
    );

    System.runAs(assignedUser) {
      System.assertEquals(
        true,
        PermissionService.hasPermissionSet('PartnerSync_Internal_Admin')
      );
    }

    System.runAs(unassignedUser) {
      System.assertEquals(
        false,
        PermissionService.hasPermissionSet('PartnerSync_Internal_Admin')
      );
    }
  }

  @IsTest
  static void hasAnyPermissionSetTrueIfAnyMatches() {
    User assignedUser = TestUserFactory.createInternalUser();

    TestUserFactory.assignPermissionSet(
      assignedUser.Id,
      'PartnerSync_Channel_Manager'
    );

    System.runAs(assignedUser) {
      System.assertEquals(
        true,
        PermissionService.hasAnyPermissionSet(
          new List<String>{
            'PartnerSync_Internal_Admin',
            'PartnerSync_Channel_Manager'
          }
        )
      );

      System.assertEquals(
        false,
        PermissionService.hasAnyPermissionSet(
          new List<String>{ 'PartnerSync_MDF_Reviewer' }
        )
      );
    }
  }

  @IsTest
  static void hasAnyPermissionSetFalseForNullOrEmptyList() {
    System.assertEquals(false, PermissionService.hasAnyPermissionSet(null));
    System.assertEquals(
      false,
      PermissionService.hasAnyPermissionSet(new List<String>())
    );
  }

  @IsTest
  static void hasPermissionSetTrueWhenInheritedFromAssignedGroup() {
    User internalAdmin = TestUserFactory.createInternalUser();

    TestUserFactory.assignPermissionSetGroup(
      internalAdmin.Id,
      'PSG_Internal_Administrator'
    );

    System.runAs(internalAdmin) {
      System.assertEquals(
        true,
        PermissionService.hasPermissionSet('PartnerSync_AI_Admin'),
        'An assigned permission-set group should expose its component permissions.'
      );
      System.assertEquals(
        true,
        PermissionService.hasPermissionSet('PartnerSync_Content_Admin')
      );
    }
  }

  @IsTest
  static void hasCustomPermissionTrueWhenGrantedViaPermissionSet() {
    User internalAdmin = TestUserFactory.createInternalUser();
    User plainInternalUser = TestUserFactory.createInternalUser();

    TestUserFactory.assignPermissionSet(
      internalAdmin.Id,
      'PartnerSync_Internal_Admin'
    );

    System.runAs(internalAdmin) {
      System.assertEquals(
        true,
        PermissionService.hasCustomPermission('PartnerSync_Approve_Deal'),
        'Internal Admin grants PartnerSync_Approve_Deal by default.'
      );
    }

    System.runAs(plainInternalUser) {
      System.assertEquals(
        false,
        PermissionService.hasCustomPermission('PartnerSync_Approve_Deal'),
        'A user with no permission sets should not have the custom permission.'
      );
    }
  }

  @IsTest
  static void hasCustomPermissionFalseForBlankName() {
    System.assertEquals(false, PermissionService.hasCustomPermission(null));
    System.assertEquals(false, PermissionService.hasCustomPermission(''));
  }

  @IsTest
  static void hasPermissionGroupFalseWhenNotAssigned() {
    User internalUser = TestUserFactory.createInternalUser();

    System.runAs(internalUser) {
      System.assertEquals(
        false,
        PermissionService.hasPermissionGroup('PSG_Internal_Administrator')
      );
    }
  }

  @IsTest
  static void hasPermissionGroupFalseForBlankName() {
    System.assertEquals(false, PermissionService.hasPermissionGroup(null));
    System.assertEquals(false, PermissionService.hasPermissionGroup(''));
  }
}
