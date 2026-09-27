/**
 * Partner-safe row for one Implementation_Milestone__c, used in
 * ImplementationDetailDTO's milestones list.
 */
public class ImplementationMilestoneRowDTO {
  @AuraEnabled
  public Id milestoneId;
  @AuraEnabled
  public String name;
  @AuraEnabled
  public String milestoneType;
  @AuraEnabled
  public String status;
  @AuraEnabled
  public Decimal sequence;
  @AuraEnabled
  public Date plannedDate;
  @AuraEnabled
  public Date actualDate;
  @AuraEnabled
  public Date dueOn;
  @AuraEnabled
  public Boolean blocking;
  @AuraEnabled
  public Boolean required;
  @AuraEnabled
  public Decimal completionPercentage;
  @AuraEnabled
  public Integer versionNumber;
}
