@IsTest
private class RoundRobinAssignmentStrategyTest {
  @IsTest
  static void picksAPartnerWithNoPriorAssignmentFirst() {
    Account withHistory = PartnerSyncTestDataFactory.partnerAccount(
      'With History'
    );
    Account withoutHistory = PartnerSyncTestDataFactory.partnerAccount(
      'Without History'
    );
    insert new List<Account>{ withHistory, withoutHistory };

    Lead priorLead = new Lead(
      LastName = 'Lead',
      Company = 'Prior Customer',
      Lead_Distribution_Status__c = 'Pending'
    );
    insert priorLead;
    insert new Partner_Lead_Assignment__c(
      Lead__c = priorLead.Id,
      Partner_Account__c = withHistory.Id,
      Status__c = 'Assigned',
      Assignment_Strategy__c = 'Manual',
      Assigned_On__c = System.now(),
      Active_Assignment_Key__c = String.valueOf(priorLead.Id),
      Version_Number__c = 0
    );

    RoundRobinAssignmentStrategy strategy = new RoundRobinAssignmentStrategy();
    Id selected = strategy.selectPartner(
      new List<Id>{ withHistory.Id, withoutHistory.Id }
    );

    Assert.areEqual(withoutHistory.Id, selected);
  }

  @IsTest
  static void picksTheLeastRecentlyAssignedPartnerWhenAllHaveHistory() {
    Account olderAssignment = PartnerSyncTestDataFactory.partnerAccount(
      'Older Assignment'
    );
    Account newerAssignment = PartnerSyncTestDataFactory.partnerAccount(
      'Newer Assignment'
    );
    insert new List<Account>{ olderAssignment, newerAssignment };

    Lead leadOne = new Lead(
      LastName = 'Lead',
      Company = 'Customer One',
      Lead_Distribution_Status__c = 'Pending'
    );
    Lead leadTwo = new Lead(
      LastName = 'Lead',
      Company = 'Customer Two',
      Lead_Distribution_Status__c = 'Pending'
    );
    insert new List<Lead>{ leadOne, leadTwo };

    insert new Partner_Lead_Assignment__c(
      Lead__c = leadOne.Id,
      Partner_Account__c = olderAssignment.Id,
      Status__c = 'Assigned',
      Assignment_Strategy__c = 'Manual',
      Assigned_On__c = System.now().addDays(-5),
      Active_Assignment_Key__c = String.valueOf(leadOne.Id),
      Version_Number__c = 0
    );
    insert new Partner_Lead_Assignment__c(
      Lead__c = leadTwo.Id,
      Partner_Account__c = newerAssignment.Id,
      Status__c = 'Assigned',
      Assignment_Strategy__c = 'Manual',
      Assigned_On__c = System.now().addDays(-1),
      Active_Assignment_Key__c = String.valueOf(leadTwo.Id),
      Version_Number__c = 0
    );

    RoundRobinAssignmentStrategy strategy = new RoundRobinAssignmentStrategy();
    Id selected = strategy.selectPartner(
      new List<Id>{ olderAssignment.Id, newerAssignment.Id }
    );

    Assert.areEqual(olderAssignment.Id, selected);
  }

  @IsTest
  static void returnsNullForAnEmptyCandidateList() {
    RoundRobinAssignmentStrategy strategy = new RoundRobinAssignmentStrategy();
    Assert.isNull(strategy.selectPartner(new List<Id>()));
    Assert.isNull(strategy.selectPartner(null));
  }
}
