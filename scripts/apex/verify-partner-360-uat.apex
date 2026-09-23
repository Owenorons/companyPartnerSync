// End-to-end Partner 360 UAT smoke check for the psync-package-test
// subscriber org. Verifies the same underlying records that
// Partner360Service.getSummary would assemble, via direct SOQL rather than
// by calling into the packaged Apex (Partner360DTO/Partner360Controller are
// intentionally scoped "public", not "global", so they aren't visible to
// anonymous Apex run against an installed package version).
Account partner = [
  SELECT Id
  FROM Account
  WHERE Name = 'Partner 360 UAT - Blocked'
  LIMIT 1
];

psync__Partner_Onboarding__c onboarding = [
  SELECT Id, psync__Current_Stage__c, psync__Activation_Gate_Status__c
  FROM psync__Partner_Onboarding__c
  WHERE psync__Partner_Account__c = :partner.Id
  ORDER BY CreatedDate DESC
  LIMIT 1
];

Integer openDocumentCount = [
  SELECT COUNT()
  FROM psync__Partner_Document_Requirement__c
  WHERE
    psync__Onboarding__c = :onboarding.Id
    AND psync__Blocking__c = TRUE
    AND psync__Status__c != 'Accepted'
];
Integer blockingFindingCount = [
  SELECT COUNT()
  FROM psync__Partner_Assessment_Finding__c
  WHERE
    psync__Assessment__r.psync__Onboarding__c = :onboarding.Id
    AND psync__Blocking__c = TRUE
    AND psync__Status__c = 'Open'
];
Integer openAccessRequestCount = [
  SELECT COUNT()
  FROM psync__Partner_Access_Request__c
  WHERE
    psync__Onboarding__c = :onboarding.Id
    AND psync__Status__c NOT IN ('Provisioned', 'Rejected', 'Expired')
];
Integer incompleteTrainingCount = [
  SELECT COUNT()
  FROM psync__Partner_Training_Assignment__c
  WHERE
    psync__Onboarding__c = :onboarding.Id
    AND psync__Mandatory__c = TRUE
    AND psync__Status__c != 'Completed'
];
Integer openDealCount = [
  SELECT COUNT()
  FROM psync__Deal_Registration__c
  WHERE
    psync__Partner_Account__c = :partner.Id
    AND psync__Status__c NOT IN ('Rejected', 'Expired', 'Cancelled')
];
Integer openMdfCount = [
  SELECT COUNT()
  FROM psync__MDF_Request__c
  WHERE
    psync__Partner_Account__c = :partner.Id
    AND psync__Status__c IN ('Submitted', 'Under Review')
];
Integer recentEventCount = [
  SELECT COUNT()
  FROM psync__Partner_Lifecycle_Event__c
  WHERE psync__Onboarding__c = :onboarding.Id
];

List<String> blockers = new List<String>();
if (openDocumentCount > 0)
  blockers.add(openDocumentCount + ' mandatory documents');
if (blockingFindingCount > 0)
  blockers.add(blockingFindingCount + ' blocking risk findings');
if (openAccessRequestCount > 0)
  blockers.add(openAccessRequestCount + ' open access requests');
if (incompleteTrainingCount > 0)
  blockers.add(incompleteTrainingCount + ' incomplete mandatory training');

System.assertEquals('Readiness', onboarding.psync__Current_Stage__c);
System.assertEquals('Blocked', onboarding.psync__Activation_Gate_Status__c);
System.assertEquals(1, openDocumentCount);
System.assertEquals(1, blockingFindingCount);
System.assertEquals(1, openAccessRequestCount);
System.assertEquals(1, incompleteTrainingCount);
System.assertEquals(1, openDealCount);
System.assertEquals(1, openMdfCount);
System.assertEquals(4, blockers.size());
System.assertEquals(1, recentEventCount);

System.debug(
  LoggingLevel.INFO,
  'PARTNER_360_UAT verified; partnerAccountId=' +
    partner.Id +
    ' onboardingId=' +
    onboarding.Id +
    ' blockers=' +
    blockers
);
