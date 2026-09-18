/**
 * A single validation rule failure recorded against a deal registration
 * during submission.
 */
public class DealValidationFinding {
  public String ruleKey;
  public String ruleVersion;
  public String category;
  public String severity;
  public Boolean blocking;
  public String internalMessage;
  public String partnerMessage;
  public String fieldReference;
  public String remediation;
}
