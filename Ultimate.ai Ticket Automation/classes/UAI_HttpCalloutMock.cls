@isTest
global class UAI_HttpCalloutMock implements HttpCalloutMock {
    // Implement this interface method
    global HTTPResponse respond(HTTPRequest request) {
            // Create a fake response
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        response.setBody('{ "messages": [ { "text": "Test" } ], "predictedIntents": [ { "value": "60254bcd29b2a8001560c6a5", "confidence": 0.9850244522094727, "name": "Greeting" }, { "value": "60254bcd29b2a8001560c69a", "confidence": 0.009643808007240295, "name": "Thank you" }, { "value": "60254bcd29b2a8001560c6b0", "confidence": 0.002871621632948518, "name": "Affirmative" }, { "value": "60254bcd29b2a8001560c660", "confidence": 0.001035334775224328, "name": "Delivery Status" }, { "value": "60254bcd29b2a8001560c6bb", "confidence": 0.0007056953618302941, "name": "Negative" } ], "salesforceObjectParameters": [ { "key": "OwnerId", "value": "' + UserInfo.getUserId() + '", "target": "case" }] }');
        response.setStatusCode(200);
        return response; 
    }
}