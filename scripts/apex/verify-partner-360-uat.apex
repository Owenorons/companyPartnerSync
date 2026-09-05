// End-to-end Partner 360 UAT smoke check for a namespaced scratch org.
Account partner = [
  SELECT Id
  FROM Account
  WHERE Name = 'Partner 360 UAT - Blocked'
  LIMIT 1
];
psync.Partner360DTO summary = psync.Partner360Controller.getSummary(partner.Id);

System.assertEquals('Readiness', summary.currentStage);
System.assertEquals('Blocked', summary.activationGateStatus);
System.assertEquals(1, summary.openDocumentCount);
System.assertEquals(1, summary.blockingFindingCount);
System.assertEquals(1, summary.openAccessRequestCount);
System.assertEquals(1, summary.incompleteTrainingCount);
System.assertEquals(1, summary.openDealCount);
System.assertEquals(1, summary.openMdfCount);
System.assertEquals(4, summary.blockers.size());
System.assertEquals(1, summary.recentEvents.size());

System.debug(
  LoggingLevel.INFO,
  'PARTNER_360_UAT verified; summary=' + JSON.serialize(summary)
);
