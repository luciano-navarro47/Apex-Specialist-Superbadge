@isTest
global class ExceptionThrowingCalloutMock implements HttpCalloutMock {
    public HttpResponse respond(HttpRequest req){
        throw new CalloutException('Simulated callout exception');
    }
}