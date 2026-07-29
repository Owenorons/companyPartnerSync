/*
 * Dynamic picklist source for an Experience Builder component property,
 * letting admins pick a NavigationLinkSet by developer name in the page
 * editor UI. Must extend VisualEditor.DynamicPickList and stay `global` -
 * that base class and visibility are Builder-side platform requirements,
 * not a public API this org exposes intentionally.
 */
global with sharing class NavigationPickList extends VisualEditor.DynamicPickList {
  global override VisualEditor.DataRow getDefaultValue() {
    VisualEditor.DataRow defaultValue = new VisualEditor.DataRow(
      'Default Navigation',
      'Default Navigation'
    );
    return defaultValue;
  }

  global override VisualEditor.DynamicPickListRows getValues() {
    VisualEditor.DynamicPickListRows picklistValues = new VisualEditor.DynamicPickListRows();

    List<NavigationLinkSet> navigationLinkSetList = [
      SELECT MasterLabel, DeveloperName
      FROM NavigationLinkSet
      WITH USER_MODE
    ];

    for (NavigationLinkSet navigationLinkSet : navigationLinkSetList) {
      VisualEditor.DataRow value = new VisualEditor.DataRow(
        navigationLinkSet.MasterLabel,
        navigationLinkSet.DeveloperName
      );
      picklistValues.addRow(value);
    }

    return picklistValues;
  }
}
