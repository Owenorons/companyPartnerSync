/*
 * Shared HttpCalloutMock for e-signature provider tests. success() shapes
 * its body like a DocuSign envelope-creation response so the same mock
 * can drive DocuSignSignatureProvider tests.
 */
@IsTest
public class PartnerSignatureCalloutMock implements HttpCalloutMock {
  private Integer statusCode;
  private String responseBody;

  /**
   * Creates a mock that responds with a fixed status code and body.
   *
   * @param statusCode HTTP status code to return.
   * @param responseBody Raw response body to return.
   */
  public PartnerSignatureCalloutMock(Integer statusCode, String responseBody) {
    this.statusCode = statusCode;
    this.responseBody = responseBody;
  }

  /**
   * Builds a mock representing a successful DocuSign envelope-creation
   * response.
   *
   * @param envelopeId The envelope id to embed in the response body.
   * @return A mock that returns HTTP 201 with a well-formed envelope body.
   */
  public static PartnerSignatureCalloutMock success(String envelopeId) {
    Map<String, Object> body = new Map<String, Object>{
      'envelopeId' => envelopeId,
      'status' => 'sent'
    };
    return new PartnerSignatureCalloutMock(201, JSON.serialize(body));
  }

  /**
   * Builds a mock representing a failed callout.
   *
   * @param statusCode HTTP status code to return.
   * @param message Raw response body to return as the failure body.
   * @return A mock that returns the given status code and message as the response body.
   */
  public static PartnerSignatureCalloutMock failure(
    Integer statusCode,
    String message
  ) {
    return new PartnerSignatureCalloutMock(statusCode, message);
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
