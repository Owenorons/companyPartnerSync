public without sharing class AIInsightGenerationQueueable implements Queueable, Database.AllowsCallouts {
  @TestVisible
  private static Boolean skipExecutionForTest = false;

  private String serializedRequest;

  public AIInsightGenerationQueueable(AIInsightRequestDTO request) {
    serializedRequest = JSON.serialize(request);
  }

  public void execute(QueueableContext context) {
    // Custom-metadata test overrides do not cross an asynchronous transaction.
    if (Test.isRunningTest() && skipExecutionForTest) {
      return;
    }
    AIInsightRequestDTO request = (AIInsightRequestDTO) JSON.deserialize(
      serializedRequest,
      AIInsightRequestDTO.class
    );
    AIInsightGeneratorService.generate(request);
  }
}
