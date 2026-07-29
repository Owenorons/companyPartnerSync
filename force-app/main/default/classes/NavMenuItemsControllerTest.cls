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
}
