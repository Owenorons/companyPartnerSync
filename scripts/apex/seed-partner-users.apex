// PartnerSync seed step 3 of 3: create two test personas.
//
// Prerequisites:
// 1. Run seed-access-groups.apex and seed-business-data.apex.
// 2. Deploy the PartnerSync Partner Tester custom profile.
// 3. Use "Enable as Partner" on the Alderbrook Logistics Account.
// 4. Ensure the Alderbrook Account owner has a User Role.
// 5. Ensure Salesforce and Partner Community user licenses are available.

String partnerProfileName = 'PartnerSync Partner Tester';
String internalProfileName = 'Standard User';
String partnerAccountName = 'Alderbrook Logistics';
String partnerAccessGroupName = 'Alderbrook Logistics Access Group';
String partnerPermissionGroupName = 'PSG_Partner_User';
String internalPermissionGroupName = 'PSG_Internal_Administrator';

Set<String> requiredProfileNames = new Set<String>{
  partnerProfileName,
  internalProfileName
};
List<Profile> requiredProfiles = [
  SELECT Id, Name, UserType, UserLicense.Name
  FROM Profile
  WHERE Name IN :requiredProfileNames
];
Map<String, Profile> profileByName = new Map<String, Profile>();
for (Profile requiredProfile : requiredProfiles) {
  profileByName.put(requiredProfile.Name, requiredProfile);
}

if (!profileByName.containsKey(partnerProfileName)) {
  throw new IllegalArgumentException(
    'Custom profile "' +
      partnerProfileName +
      '" is not deployed. Deploy force-app/main/default/profiles/' +
      'PartnerSync Partner Tester.profile-meta.xml first.'
  );
}
if (!profileByName.containsKey(internalProfileName)) {
  throw new IllegalArgumentException(
    'Internal profile "' + internalProfileName + '" is not available.'
  );
}

Profile partnerProfile = profileByName.get(partnerProfileName);
if (
  partnerProfile.UserType == 'Standard' ||
  partnerProfile.UserLicense.Name != 'Partner Community'
) {
  throw new IllegalArgumentException(
    partnerProfileName + ' must use the Partner Community license.'
  );
}

List<Account> partnerAccounts = [
  SELECT Id, Name, IsPartner, Owner.UserRoleId
  FROM Account
  WHERE Name = :partnerAccountName
  LIMIT 1
];
if (partnerAccounts.isEmpty()) {
  throw new IllegalArgumentException(
    'Seed partner Account "' +
      partnerAccountName +
      '" is missing. Run seed-business-data.apex first.'
  );
}
Account partnerAccount = partnerAccounts[0];

if (!partnerAccount.IsPartner) {
  throw new IllegalArgumentException(
    partnerAccountName +
    ' has Account.IsPartner = false. Open the Account and use "Enable as Partner".'
  );
}
if (partnerAccount.Owner.UserRoleId == null) {
  throw new IllegalArgumentException(
    'The owner of "' + partnerAccountName + '" must have a User Role.'
  );
}

List<Contact> partnerContacts = [
  SELECT Id, FirstName, LastName, Email
  FROM Contact
  WHERE AccountId = :partnerAccount.Id AND psync__Is_Partner_User__c = TRUE
  ORDER BY CreatedDate
  LIMIT 1
];
if (partnerContacts.isEmpty()) {
  throw new IllegalArgumentException(
    'Alderbrook Logistics has no PartnerSync partner Contact.'
  );
}
Contact partnerContact = partnerContacts[0];

List<Group> accessGroups = [
  SELECT Id, Name
  FROM Group
  WHERE Name = :partnerAccessGroupName AND Type = 'Regular'
  LIMIT 1
];
if (accessGroups.isEmpty()) {
  throw new IllegalArgumentException(
    'Seed access group is missing. Run seed-access-groups.apex first.'
  );
}
Group partnerAccessGroup = accessGroups[0];

Map<String, PermissionSetGroup> permissionGroupByName = new Map<String, PermissionSetGroup>();
Set<String> requiredPermissionGroupNames = new Set<String>{
  partnerPermissionGroupName,
  internalPermissionGroupName
};
for (PermissionSetGroup permissionGroup : [
  SELECT Id, DeveloperName
  FROM PermissionSetGroup
  WHERE DeveloperName IN :requiredPermissionGroupNames
]) {
  permissionGroupByName.put(permissionGroup.DeveloperName, permissionGroup);
}
if (
  !permissionGroupByName.containsKey(partnerPermissionGroupName) ||
  !permissionGroupByName.containsKey(internalPermissionGroupName)
) {
  throw new IllegalArgumentException(
    'Required PartnerSync permission-set groups are not deployed.'
  );
}

String orgToken = UserInfo.getOrganizationId().toLowerCase();
String partnerUsername = 'partner.tester.' + orgToken + '@example.com';
String internalUsername = 'internal.admin.tester.' + orgToken + '@example.com';

Map<String, User> userByUsername = new Map<String, User>();
Set<String> testerUsernames = new Set<String>{
  partnerUsername,
  internalUsername
};
for (User existingUser : [
  SELECT Id, Username, ContactId, IsActive
  FROM User
  WHERE Username IN :testerUsernames OR ContactId = :partnerContact.Id
]) {
  if (existingUser.ContactId == partnerContact.Id) {
    userByUsername.put(partnerUsername, existingUser);
  }
  if (testerUsernames.contains(existingUser.Username)) {
    userByUsername.put(existingUser.Username, existingUser);
  }
}
for (User existingTester : userByUsername.values()) {
  if (!existingTester.IsActive) {
    throw new IllegalArgumentException(
      'Existing tester user "' + existingTester.Username + '" is inactive.'
    );
  }
}

List<User> usersToCreate = new List<User>();
if (!userByUsername.containsKey(partnerUsername)) {
  usersToCreate.add(
    new User(
      FirstName = partnerContact.FirstName,
      LastName = partnerContact.LastName + ' Partner Tester',
      Email = partnerContact.Email,
      Username = partnerUsername,
      Alias = 'ptnrtst',
      TimeZoneSidKey = 'Australia/Melbourne',
      LocaleSidKey = 'en_AU',
      EmailEncodingKey = 'UTF-8',
      LanguageLocaleKey = 'en_US',
      ProfileId = partnerProfile.Id,
      ContactId = partnerContact.Id
    )
  );
}
if (!userByUsername.containsKey(internalUsername)) {
  usersToCreate.add(
    new User(
      FirstName = 'PartnerSync',
      LastName = 'Internal Admin Tester',
      Email = internalUsername,
      Username = internalUsername,
      Alias = 'intatst',
      TimeZoneSidKey = 'Australia/Melbourne',
      LocaleSidKey = 'en_AU',
      EmailEncodingKey = 'UTF-8',
      LanguageLocaleKey = 'en_US',
      ProfileId = profileByName.get(internalProfileName).Id
    )
  );
}

if (!usersToCreate.isEmpty()) {
  insert usersToCreate;
  for (User createdUser : usersToCreate) {
    userByUsername.put(createdUser.Username, createdUser);
  }
}

User partnerTester = userByUsername.get(partnerUsername);
User internalAdminTester = userByUsername.get(internalUsername);

List<GroupMember> existingMemberships = [
  SELECT Id
  FROM GroupMember
  WHERE GroupId = :partnerAccessGroup.Id AND UserOrGroupId = :partnerTester.Id
  LIMIT 1
];
Integer createdMembershipCount = 0;
if (existingMemberships.isEmpty()) {
  insert new GroupMember(
    GroupId = partnerAccessGroup.Id,
    UserOrGroupId = partnerTester.Id
  );
  createdMembershipCount = 1;
}

Map<Id, Id> requiredPermissionGroupByUserId = new Map<Id, Id>{
  partnerTester.Id => permissionGroupByName.get(partnerPermissionGroupName).Id,
  internalAdminTester.Id => permissionGroupByName
    .get(internalPermissionGroupName)
    .Id
};
Set<String> existingAssignmentKeys = new Set<String>();
for (PermissionSetAssignment assignment : [
  SELECT AssigneeId, PermissionSetGroupId
  FROM PermissionSetAssignment
  WHERE AssigneeId IN :requiredPermissionGroupByUserId.keySet()
]) {
  existingAssignmentKeys.add(
    assignment.AssigneeId + ':' + assignment.PermissionSetGroupId
  );
}

List<PermissionSetAssignment> assignmentsToCreate = new List<PermissionSetAssignment>();
for (Id userId : requiredPermissionGroupByUserId.keySet()) {
  Id permissionGroupId = requiredPermissionGroupByUserId.get(userId);
  if (!existingAssignmentKeys.contains(userId + ':' + permissionGroupId)) {
    assignmentsToCreate.add(
      new PermissionSetAssignment(
        AssigneeId = userId,
        PermissionSetGroupId = permissionGroupId
      )
    );
  }
}
if (!assignmentsToCreate.isEmpty()) {
  insert assignmentsToCreate;
}

System.debug(
  LoggingLevel.INFO,
  '=== Test personas ready === partnerUsername:' +
    partnerUsername +
    ' internalAdminUsername:' +
    internalUsername +
    ' createdUsers:' +
    usersToCreate.size() +
    ' createdMemberships:' +
    createdMembershipCount +
    ' createdPermissionAssignments:' +
    assignmentsToCreate.size()
);
