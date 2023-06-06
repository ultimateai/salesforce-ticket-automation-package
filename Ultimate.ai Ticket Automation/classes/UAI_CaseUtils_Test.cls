@isTest
public class UAI_CaseUtils_Test {


    @testSetup 
    static void createTestData(){



        UAI_AppSetting__c settings = new UAI_AppSetting__c();
        settings.User__c = 'user';
        settings.Pass__c = 'pass';
        insert settings;

        Case testCase = new Case(Subject = 'Test', Description = 'Hello this is an email t@x.com and this is a phone +49 15792345567');
        insert testCase;

    }

    @isTest
    public static void processBotRequestTest(){

        Group g;

        System.runAs ( new User(Id = UserInfo.getUserId()) ) {
            g = new Group(Type='Queue', Name='Queue name');
            insert g;
            QueueSObject q = new QueueSObject(SobjectType='case', QueueId=g.Id);
            insert q;
        } 
        Test.setMock(HttpCalloutMock.class, new UAI_HttpCalloutMock()); 
        Test.startTest();
        Case testCase2 = new Case(OwnerId=[SELECT Id, Name FROM Group ORDER BY CreatedDate DESC LIMIT 1][0].Id, Subject = 'Test 2', Description = 'Hello this is an email t@x.com and this is a phone +49 15792345567');
        insert testCase2;

        Case testcase = [SELECT Id, Subject, Description, OwnerId FROM Case WHERE Subject ='Test 2' LIMIT 1];
   

        system.assertNotEquals(UserInfo.getUserId(), testcase.OwnerId);
        UAI_CaseUtils.processBotRequest(testcase.Id, 'Web', 'bot_id', testcase.Subject, testcase.Description);
        Test.stopTest();
        testcase = [SELECT Id, Subject, Description, OwnerId FROM Case LIMIT 1];
        system.assertEquals(UserInfo.getUserId(), testcase.OwnerId);

        // check log reponse
        UAI_BotResponse__c botResponse = [SELECT Id, Response__c FROM UAI_BotResponse__c LIMIT 1 ];
        UAI_BotResponse botResponseObject = (UAI_BotResponse)JSON.deserializeStrict(botResponse.Response__c, UAI_BotResponse.class);
        system.assertEquals(5, botResponseObject.predictedIntents.size());
        system.assertEquals(1, botResponseObject.messages.size());
        system.assertEquals('Test', botResponseObject.messages[0].text);
    }

    @isTest
    public static void processBotRequestTranscriptTest(){

        Group g;

        System.runAs ( new User(Id = UserInfo.getUserId()) ) {
            g = new Group(Type='Queue', Name='Queue name');
            insert g;
            QueueSObject q = new QueueSObject(SobjectType='case', QueueId=g.Id);
            insert q;
        } 
        Test.setMock(HttpCalloutMock.class, new UAI_HttpWithTranscriptCalloutMock());  
        Test.startTest();
        Case testCase2 = new Case(OwnerId=[SELECT Id, Name FROM Group ORDER BY CreatedDate DESC LIMIT 1][0].Id, Subject = 'Test 2', Description = 'Hello this is an email t@x.com and this is a phone +49 15792345567');
        insert testCase2;

        // Only valid for orgs with LiveChat enabled
        /*LiveChatVisitor visitor = new LiveChatVisitor();
        insert visitor;

        LiveChatTranscript transcript = new LiveChatTranscript(CaseId = testCase2.Id, LiveChatVisitorId = visitor.Id);
        insert transcript;*/

        Case testcase = [SELECT Id, Subject, Description, OwnerId FROM Case WHERE Subject ='Test 2' LIMIT 1];
   

        system.assertNotEquals(UserInfo.getUserId(), testcase.OwnerId);
        UAI_CaseUtils.processBotRequest(testcase.Id, 'Web', 'bot_id', testcase.Subject, testcase.Description);
        Test.stopTest();
        testcase = [SELECT Id, Subject, Description, OwnerId FROM Case LIMIT 1];
        system.assertEquals(UserInfo.getUserId(), testcase.OwnerId);
    }

    @isTest
    public static void maskMessageTest(){
        String maskMessage = UAI_CaseUtils.maskMessage('Hello this is an email t@x.com and this is a phone +49 15792345567');
        system.assertEquals('Hello this is an email <EMAIL> and this is a phone <PHONE>', maskMessage);
    }

    @isTest
    public static void logResponseTest(){

        Case testcase = [SELECT Id FROM Case WHERE Subject = 'Test' LIMIT 1];
        
        Test.startTest();
        UAI_CaseUtils.logResponse(testcase.Id, 'Test', 'bot_id', 200, '{}', '{}');
        Test.stopTest();

        system.assertEquals([SELECT Id, Type__c FROM UAI_BotResponse__c LIMIT 1][0].Type__c, 'Test');

    }

    @isTest
    public static void processCaseFieldsTest(){
        
        Case testcase = [SELECT Id FROM Case WHERE Subject = 'Test' LIMIT 1];

        Test.startTest();
        UAI_BotResponse botResponses = (UAI_BotResponse)JSON.deserialize( '{ "messages": [ { "text": "" } ], "predictedIntents": [ { "value": "60254bcd29b2a8001560c6a5", "confidence": 0.9850244522094727, "name": "Greeting" }, { "value": "60254bcd29b2a8001560c69a", "confidence": 0.009643808007240295, "name": "Thank you" }, { "value": "60254bcd29b2a8001560c6b0", "confidence": 0.002871621632948518, "name": "Affirmative" }, { "value": "60254bcd29b2a8001560c660", "confidence": 0.001035334775224328, "name": "Delivery Status" }, { "value": "60254bcd29b2a8001560c6bb", "confidence": 0.0007056953618302941, "name": "Negative" } ], "salesforceObjectParameters": [ { "key": "OwnerId", "value": "' + UserInfo.getUserId() + '", "target": "case" }, { "key": "fakefield123__c", "value": "test", "target": "case" }] }', UAI_BotResponse.class);
        UAI_ProcessedCase processedCase = UAI_CaseUtils.processCaseFields(testcase.Id, botResponses);

        system.assertEquals(UserInfo.getUserId(), processedCase.record.get('OwnerId'));
        system.assertEquals( String.format(System.label.UAI_FIELD_NOT_VALID, new List<String>{'fakefield123__c'}) , processedCase.partialErrors[0]);

        Test.stopTest();
    
    }

    @isTest
    public static void convertFieldTest(){
        system.assertEquals( String.valueOf(UAI_CaseUtils.convertField('case', 'status', 'Test')), 'Test');
        system.assertEquals( (DateTime)(UAI_CaseUtils.convertField('case', 'createddate', '2021-01-01T17:07:23.000+0000')), DateTime.newInstance(2021,1,1,17,7,23));
        system.assertEquals( Integer.valueOf( UAI_CaseUtils.convertField('account', 'NumberOfEmployees', '100') ), 100);
        system.assertEquals( (Decimal)( UAI_CaseUtils.convertField('account', 'AnnualRevenue', '100.1') ), 100.1);
    } 
}