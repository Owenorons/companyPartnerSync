@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class DealReviewCommandService {
  public static List<Deal_Review__c> execute(List<DealReviewCommand> commands) {
    if (commands == null || commands.isEmpty())
      return new List<Deal_Review__c>();
    Set<Id> reviewIds = new Set<Id>();
    for (DealReviewCommand command : commands) {
      if (
        command == null ||
        command.reviewId == null ||
        String.isBlank(command.action)
      )
        throw new DealReviewCommandException(
          'Review, action, and version are required.'
        );
      reviewIds.add(command.reviewId);
    }
    Map<Id, Deal_Review__c> reviews = new Map<Id, Deal_Review__c>(
      [
        SELECT
          Id,
          Deal__c,
          Plan__c,
          Review_Key__c,
          Status__c,
          Outcome__c,
          Assigned_To__c,
          Version_Number__c,
          Blocking__c
        FROM Deal_Review__c
        WHERE Id IN :reviewIds
        FOR UPDATE
      ]
    );
    List<Deal_Information_Request__c> requests = new List<Deal_Information_Request__c>();
    Set<Id> completedPlans = new Set<Id>();
    for (DealReviewCommand command : commands) {
      Deal_Review__c review = reviews.get(command.reviewId);
      if (review == null)
        throw new DealReviewCommandException('Review was not found.');
      if (
        command.expectedVersion == null ||
        review.Version_Number__c != command.expectedVersion
      )
        throw new DealReviewCommandException(
          'The review changed. Refresh and retry.'
        );
      apply(command, review, requests);
      review.Version_Number__c++;
      if (review.Status__c == 'Completed' || review.Status__c == 'Waived')
        completedPlans.add(review.Plan__c);
    }
    Database.update(reviews.values(), AccessLevel.SYSTEM_MODE);
    if (!requests.isEmpty())
      Database.insert(requests, AccessLevel.SYSTEM_MODE);
    releaseDependencies(completedPlans);
    return reviews.values();
  }

  private static void apply(
    DealReviewCommand command,
    Deal_Review__c review,
    List<Deal_Information_Request__c> requests
  ) {
    String action = command.action.trim();
    if (action == 'Start') {
      requireStatus(review, new Set<String>{ 'Ready', 'Escalated' });
      review.Status__c = 'In Progress';
      review.Started_On__c = System.now();
    } else if (action == 'Complete') {
      requireStatus(review, new Set<String>{ 'In Progress' });
      if (String.isBlank(command.outcome))
        throw new DealReviewCommandException('Outcome is required.');
      review.Status__c = 'Completed';
      review.Outcome__c = command.outcome;
      review.Completed_On__c = System.now();
    } else if (action == 'Request Info') {
      requireStatus(review, new Set<String>{ 'In Progress' });
      if (String.isBlank(command.question))
        throw new DealReviewCommandException('Question is required.');
      review.Status__c = 'Waiting for Information';
      requests.add(
        new Deal_Information_Request__c(
          Deal__c = review.Deal__c,
          Review__c = review.Id,
          Question__c = command.question,
          Audience__c = command.audience,
          Evidence_Requirement__c = command.evidenceRequirement,
          Due_On__c = command.dueOn,
          Status__c = 'Open'
        )
      );
    } else if (action == 'Resume') {
      requireStatus(review, new Set<String>{ 'Waiting for Information' });
      review.Status__c = 'In Progress';
    } else if (action == 'Reassign') {
      requireOpen(review);
      if (command.assigneeId == null)
        throw new DealReviewCommandException('Assignee is required.');
      review.Assigned_To__c = command.assigneeId;
      review.Assignment_Source__c = 'Manual Reassignment';
    } else if (action == 'Recuse') {
      requireOpen(review);
      if (String.isBlank(command.reason))
        throw new DealReviewCommandException('Recusal reason is required.');
      review.Recusal_Reason__c = command.reason;
      review.Assigned_To__c = null;
      review.Status__c = 'Routing Failed';
      review.Assignment_Source__c = 'Recused - reassignment required';
    } else if (action == 'Waive') {
      requireOpen(review);
      if (String.isBlank(command.reason))
        throw new DealReviewCommandException('Waiver reason is required.');
      review.Waiver_Reason__c = command.reason;
      review.Outcome__c = 'Waived';
      review.Status__c = 'Waived';
      review.Completed_On__c = System.now();
    } else if (action == 'Escalate') {
      requireOpen(review);
      review.Status__c = 'Escalated';
      review.Escalated_On__c = System.now();
    } else if (action == 'Cancel') {
      requireOpen(review);
      review.Status__c = 'Cancelled';
      review.Completed_On__c = System.now();
    } else {
      throw new DealReviewCommandException(
        'Unsupported review action: ' + action
      );
    }
  }

  private static void releaseDependencies(Set<Id> planIds) {
    if (planIds.isEmpty())
      return;
    List<Deal_Review__c> planReviews = [
      SELECT Id, Plan__c, Review_Key__c, Depends_On_Key__c, Status__c
      FROM Deal_Review__c
      WHERE Plan__c IN :planIds
    ];
    Map<Id, Set<String>> doneKeys = new Map<Id, Set<String>>();
    for (Deal_Review__c item : planReviews) {
      if (!doneKeys.containsKey(item.Plan__c))
        doneKeys.put(item.Plan__c, new Set<String>());
      if (item.Status__c == 'Completed' || item.Status__c == 'Waived')
        doneKeys.get(item.Plan__c).add(item.Review_Key__c);
    }
    List<Deal_Review__c> released = new List<Deal_Review__c>();
    for (Deal_Review__c item : planReviews) {
      if (
        item.Status__c == 'Blocked' &&
        doneKeys.get(item.Plan__c).contains(item.Depends_On_Key__c)
      ) {
        item.Status__c = 'Ready';
        released.add(item);
      }
    }
    if (!released.isEmpty())
      Database.update(released, AccessLevel.SYSTEM_MODE);
  }

  private static void requireOpen(Deal_Review__c review) {
    requireStatus(
      review,
      new Set<String>{
        'Ready',
        'In Progress',
        'Waiting for Information',
        'Escalated',
        'Routing Failed'
      }
    );
  }
  private static void requireStatus(
    Deal_Review__c review,
    Set<String> allowed
  ) {
    if (!allowed.contains(review.Status__c))
      throw new DealReviewCommandException(
        'Action is not allowed from ' + review.Status__c + '.'
      );
  }
  public class DealReviewCommandException extends Exception {
  }
}
