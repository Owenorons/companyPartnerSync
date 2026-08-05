// PartnerSync seed step 1 of 3.
//
// Setup DML only. Run this before seed-business-data.apex so the business-data
// transaction can create Partner_Access_Group__c mappings without mixing setup
// and non-setup DML.
List<String> requiredGroupNames = new List<String>{
  'Alderbrook Logistics Access Group',
  'Bramwell Retail Group Access Group',
  'Northlake Systems Access Group',
  'Kestrel Freight Alliance Access Group'
};

Set<String> existingGroupNames = new Set<String>();
for (Group existingGroup : [
  SELECT Name
  FROM Group
  WHERE Name IN :requiredGroupNames AND Type = 'Regular'
]) {
  existingGroupNames.add(existingGroup.Name);
}

List<Group> groupsToCreate = new List<Group>();
for (String groupName : requiredGroupNames) {
  if (!existingGroupNames.contains(groupName)) {
    groupsToCreate.add(new Group(Name = groupName, Type = 'Regular'));
  }
}

if (!groupsToCreate.isEmpty()) {
  insert groupsToCreate;
}

System.debug(
  LoggingLevel.INFO,
  '=== Access-group seed complete === created:' +
    groupsToCreate.size() +
    ' existing:' +
    existingGroupNames.size()
);
