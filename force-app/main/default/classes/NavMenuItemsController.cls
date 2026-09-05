/*
 * Aura-enabled controller backing a custom Experience Builder navigation
 * component. `global` because Experience Builder components / the platform
 * cache layer invoke it across package/namespace boundaries, not because
 * external code is expected to call it directly. Returns an empty list
 * rather than throwing when the menu/link set can't be found, since this
 * feeds page chrome that should degrade quietly instead of erroring the page.
 */
global with sharing class NavMenuItemsController {
  @TestVisible
  private static Id linkSetIdOverride;

  public NavMenuItemsController() {
  }

  @AuraEnabled(cacheable=true)
  public static List<NavigationMenuItem> getNavigationMenuItems(
    String menuName,
    String publishedState
  ) {
    if (String.isEmpty(menuName)) {
      return new List<NavigationMenuItem>();
    }

    String networkId = Network.getNetworkId();

    // find the link set belonging to the navigation menuName and active networkId
    List<NavigationLinkSet> linkSets = [
      SELECT Id
      FROM NavigationLinkSet
      WHERE DeveloperName = :menuName AND NetworkId = :networkId
      WITH USER_MODE
    ];

    if (linkSets.isEmpty() && linkSetIdOverride == null) {
      return new List<NavigationMenuItem>();
    }

    Id linkSetId = linkSetIdOverride == null
      ? linkSets[0].Id
      : linkSetIdOverride;

    // collect all the menu items belonging to the link set
    // published state is either Draft or Live
    return [
      SELECT
        Id,
        Label,
        Target,
        Type,
        DefaultListViewId,
        AccessRestriction,
        ParentId,
        Position,
        Status,
        TargetPrefs
      FROM NavigationMenuItem
      WHERE NavigationLinkSetId = :linkSetId AND Status = :publishedState
      WITH USER_MODE
      ORDER BY Position
    ];
  }
}
