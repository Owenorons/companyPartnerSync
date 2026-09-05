/*
 * Covers NavMenuItemsController's graceful-empty-list behavior (blank or
 * unknown menu name) rather than a real NavigationLinkSet/NavigationMenuItem
 * lookup, since those are Experience Cloud metadata records that aren't
 * straightforward to create in a test context.
 */
@IsTest
private class NavMenuItemsControllerTest {
  @IsTest
  static void blankMenuNameReturnsEmptyList() {
    List<NavigationMenuItem> results = NavMenuItemsController.getNavigationMenuItems(
      '',
      'Live'
    );

    System.assertEquals(0, results.size());
  }

  @IsTest
  static void unknownMenuNameReturnsEmptyListInsteadOfThrowing() {
    List<NavigationMenuItem> results = NavMenuItemsController.getNavigationMenuItems(
      'Does_Not_Exist',
      'Live'
    );

    System.assertEquals(0, results.size());
  }

  @IsTest
  static void queriesItemsForResolvedLinkSet() {
    String keyPrefix = NavigationLinkSet.SObjectType.getDescribe()
      .getKeyPrefix();
    NavMenuItemsController.linkSetIdOverride = Id.valueOf(
      keyPrefix + '000000000001'
    );
    try {
      List<NavigationMenuItem> results = NavMenuItemsController.getNavigationMenuItems(
        'Test_Menu',
        'Live'
      );
      Assert.areEqual(0, results.size());
    } finally {
      NavMenuItemsController.linkSetIdOverride = null;
    }
  }
}
