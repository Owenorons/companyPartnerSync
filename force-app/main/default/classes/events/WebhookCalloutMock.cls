/*
 * Shared HttpCalloutMock for webhook dispatch tests. Returns a fixed
 * status code and body regardless of the outgoing request.
 */
@IsTest
public class WebhookCalloutMock implements HttpCalloutMock {
  private Integer statusCode;
  private String responseBody;

  /**
   * Creates a mock that responds with a fixed status code and body.
   *
   * @param statusCode HTTP status code to return.
   * @param responseBody Raw response body to return.
   */
  public WebhookCalloutMock(Integer statusCode, String responseBody) {
    this.statusCode = statusCode;
    this.responseBody = responseBody;
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
