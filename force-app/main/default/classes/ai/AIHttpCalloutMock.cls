/*
 * Shared HttpCalloutMock for AI provider tests. success() shapes its body
 * like an OpenAI-compatible chat completion response (choices/message/
 * content plus usage.total_tokens) so the same mock can drive
 * OpenAICompatibleResponseParser for both OpenAIProvider and
 * AzureOpenAIProvider tests.
 */
@IsTest
public class AIHttpCalloutMock implements HttpCalloutMock {
  private Integer statusCode;
  private String responseBody;

  public AIHttpCalloutMock(Integer statusCode, String responseBody) {
    this.statusCode = statusCode;
    this.responseBody = responseBody;
  }

  public static AIHttpCalloutMock success(String content) {
    Map<String, Object> body = new Map<String, Object>{
      'model' => 'gpt-5',
      'choices' => new List<Object>{
        new Map<String, Object>{
          'message' => new Map<String, Object>{
            'role' => 'assistant',
            'content' => content
          }
        }
      },
      'usage' => new Map<String, Object>{ 'total_tokens' => 42 }
    };

    return new AIHttpCalloutMock(200, JSON.serialize(body));
  }

  public static AIHttpCalloutMock failure(Integer statusCode, String message) {
    return new AIHttpCalloutMock(statusCode, message);
  }

  public HttpResponse respond(HttpRequest request) {
    HttpResponse response = new HttpResponse();
    response.setStatusCode(statusCode);
    response.setBody(responseBody);
    return response;
  }
}
