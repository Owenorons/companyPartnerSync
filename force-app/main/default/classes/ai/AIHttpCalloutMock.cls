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

  /**
   * Creates a mock that responds with a fixed status code and body.
   *
   * @param statusCode HTTP status code to return.
   * @param responseBody Raw response body to return.
   */
  public AIHttpCalloutMock(Integer statusCode, String responseBody) {
    this.statusCode = statusCode;
    this.responseBody = responseBody;
  }

  /**
   * Builds a mock representing a successful OpenAI-compatible chat
   * completion response, with the given content wrapped in the
   * structured summary/recommendation/rationale/confidence JSON that
   * OpenAICompatibleResponseParser expects.
   *
   * @param content The summary text to embed as the structured response content.
   * @return A mock that returns HTTP 200 with a well-formed chat completion body.
   */
  public static AIHttpCalloutMock success(String content) {
    String structuredContent = JSON.serialize(
      new Map<String, Object>{
        'summary' => content,
        'recommendation' => 'Follow the recommended next step.',
        'rationale' => 'Based on the supplied partner context.',
        'confidence' => 82
      }
    );
    Map<String, Object> body = new Map<String, Object>{
      'model' => 'gpt-5',
      'choices' => new List<Object>{
        new Map<String, Object>{
          'message' => new Map<String, Object>{
            'role' => 'assistant',
            'content' => structuredContent
          }
        }
      },
      'usage' => new Map<String, Object>{ 'total_tokens' => 42 }
    };

    return new AIHttpCalloutMock(200, JSON.serialize(body));
  }

  /**
   * Builds a mock representing a failed callout.
   *
   * @param statusCode HTTP status code to return.
   * @param message Raw response body to return as the failure body.
   * @return A mock that returns the given status code and message as the response body.
   */
  public static AIHttpCalloutMock failure(Integer statusCode, String message) {
    return new AIHttpCalloutMock(statusCode, message);
  }

  /**
   * Implements HttpCalloutMock by returning the configured status code and body.
   *
   * @param request The outgoing request (ignored; the response is fixed).
   * @return An HttpResponse with the configured status code and body.
   */
  public HttpResponse respond(HttpRequest request) {
    HttpResponse response = new HttpResponse();
    response.setStatusCode(statusCode);
    response.setBody(responseBody);
    return response;
  }
}
