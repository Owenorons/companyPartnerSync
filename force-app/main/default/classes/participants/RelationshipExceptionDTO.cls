/**
 * A row in the internal "Relationship Exceptions" workbench view: partner
 * account relationships that are Suspended or Expired and may need
 * administrative attention.
 */
public class RelationshipExceptionDTO {
  @AuraEnabled
  public Id relationshipId;
  @AuraEnabled
  public String sourceAccountName;
  @AuraEnabled
  public String targetAccountName;
  @AuraEnabled
  public String status;
  @AuraEnabled
  public Date effectiveTo;
}
