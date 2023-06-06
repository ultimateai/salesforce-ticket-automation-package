@isTest
public class UAI_UtilREST_Test {

    @testSetup
    static void createData(){

        UAI_AppSetting__c settings = new UAI_AppSetting__c();
        settings.User__c = 'user';
        settings.Pass__c = 'pass';
        insert settings;

    }


    @isTest
    public static void doCalloutTest(){

        // Set mock callout class 
        Test.setMock(HttpCalloutMock.class, new UAI_HttpCalloutMock()); 

        Test.startTest();

        HttpResponse response = UAI_UtilREST.doCallout('Bot', '{ "botId":"60254bcd29b2a8001560c64c", "conversationId":"234567890134567", "message":"moi", "subject": "Hello!" }');

        Test.stopTest();

        String contentType = response.getHeader('Content-Type');
        System.assert(contentType == 'application/json');
        String actualValue = response.getBody();

        String expectedValue = '{ "messages": [ { "text": "Test" } ], "predictedIntents": [ { "value": "60254bcd29b2a8001560c6a5", "confidence": 0.9850244522094727, "name": "Greeting" }, { "value": "60254bcd29b2a8001560c69a", "confidence": 0.009643808007240295, "name": "Thank you" }, { "value": "60254bcd29b2a8001560c6b0", "confidence": 0.002871621632948518, "name": "Affirmative" }, { "value": "60254bcd29b2a8001560c660", "confidence": 0.001035334775224328, "name": "Delivery Status" }, { "value": "60254bcd29b2a8001560c6bb", "confidence": 0.0007056953618302941, "name": "Negative" } ], "salesforceObjectParameters": [ { "key": "OwnerId", "value": "' + UserInfo.getUserId() + '", "target": "case" }] }';
        System.assertEquals(actualValue, expectedValue);
        System.assertEquals(200, response.getStatusCode());
        

    }

    @isTest
    public static void doErrorCalloutTest(){

        // Set mock callout class 
        Test.setMock(HttpCalloutMock.class, new UAI_HttpErrorLogCalloutMock()); 

        Test.startTest();

        HttpResponse response = UAI_UtilREST.doCallout('Error', '{ "errorMessage": "SObject transcript not valid", "conversationId": "50009000009FkBGAA0", "botId": "60254bcd29b2a8001560c64c" }');

        Test.stopTest();
        
        String contentType = response.getHeader('Content-Type');
        System.assert(contentType == 'application/json');
        String actualValue = response.getBody();

        String expectedValue = '{}';
        System.assertEquals(actualValue, expectedValue);
        System.assertEquals(200, response.getStatusCode());
        

    }
    

}