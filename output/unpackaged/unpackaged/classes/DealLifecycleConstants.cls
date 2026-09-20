/**
 * Shared constant values for the deal lifecycle command framework, including
 * supported aggregate/dimension identifiers and command outcome labels.
 */
public abstract class DealLifecycleConstants {
  public static final String AGGREGATE_REGISTRATION = 'Deal Registration';
  public static final String DIMENSION_REGISTRATION = 'Registration';

  public static final String OUTCOME_COMPLETED = 'Completed';
  public static final String OUTCOME_COMMAND_IN_PROGRESS = 'Command In Progress';
  public static final String OUTCOME_VERSION_CONFLICT = 'Version Conflict';
}
