@isTest
public class UAI_LogErrorQueueable_Test {

    @testSetup
    static void createData(){

        UAI_AppSetting__c settings = new UAI_AppSetting__c();
        settings.User__c = 'user';
        settings.Pass__c = 'pass';
        insert settings;

    }

    @isTest
    static void executeTest(){
        
        Test.setMock(HttpCalloutMock.class, new UAI_HttpErrorLogCalloutMock()); 
        Test.startTest();
 
        UAI_LogErrorQueueable queuable = new UAI_LogErrorQueueable('{ "errorMessage": "SObject transcript not valid", "conversationId": "50009000009FkBGAA0", "botId": "60254bcd29b2a8001560c64c" }');
        queuable.execute(null);

        Test.stopTest();
    }

}