public without sharing class UAI_CaseUtils {

    public static final String MODE_BOT = 'Bot';
    public static final String MODE_ERRORLOG = 'Error';

    public static final String BASIC_AUTH = 'BASIC';
    public static final String ERROR_PREFIX = 'Error: \n\r';

    @future (callout=true)
    public static void processBotRequest(Id caseId, String type, String botId, String subject, String body){

        UAI_BotRequest request = new UAI_BotRequest();
        request.botId = botId;
        request.conversationId = caseId;

        UAI_AppSetting__c setting = UAI_UtilREST.setting;
        
        if(setting == null){
            throw new UAI_UtilREST.CalloutCustomException('Setting recording missing');
        }
        
        if(body != null){
            body = body.stripHtmlTags();
        }

        if(subject != null){
            subject = subject.stripHtmlTags();
        }

        request.message = (setting.EnableMasking__c ? maskMessage(body) : body); 
        request.subject = (setting.EnableMasking__c ? maskMessage(subject) : subject); 

        String bodyText = JSON.serializePretty(request);

        HttpResponse response = UAI_UtilREST.doCallout(MODE_BOT, bodyText); 

        UAI_BotResponse__c log = logResponse(caseId, type, botId, response.getStatusCode() , bodyText, response.getBody());

        if(response.getStatusCode() == 200){
            UAI_BotResponse botResponses = (UAI_BotResponse)JSON.deserialize( response.getBody(), UAI_BotResponse.class);
            if(botResponses.salesforceObjectParameters != null){

                UAI_ProcessedCase processedCase = processCaseFields (caseId, botResponses);
                String exceptionText;

                try{
                    update processedCase.record;
                    if(processedCase.chatTranscript != null){
                        update processedCase.chatTranscript;
                    }
                    log.CaseFieldUpdate__c = JSON.serializePretty(processedCase); 
                }catch(Exception e){
                    log.CaseFieldUpdate__c = ERROR_PREFIX + JSON.serializePretty(e);
                    exceptionText = 'Exception: ' + e.getMessage() + ' Line:' + e.getLineNumber();
                }finally{
                    update log;
                    if(exceptionText != null){
                        System.enqueueJob(new UAI_LogErrorQueueable( JSON.serialize( new UAI_ErrorLogRequest(botId, caseId, exceptionText))));
                    }else if(processedCase.partialErrors.size()>0){
                        System.enqueueJob(new UAI_LogErrorQueueable( JSON.serialize( new UAI_ErrorLogRequest(botId, caseId, String.join(processedCase.partialErrors,'\n')))));
                    } 
                } 
            }
        }else{
            System.enqueueJob(new UAI_LogErrorQueueable( JSON.serialize( new UAI_ErrorLogRequest(botId, caseId, response.getBody()))));
        } 

    }

    public static String maskMessage(String message){

        // Mask Email
        String regexEmail = '[a-zA-Z0-9-_.]+@[a-zA-Z0-9-_.]+';

        Pattern p = Pattern.compile(regexEmail); 
        Matcher mo = p.matcher(message); 
        while (mo.find()) { 
            System.debug(mo.group()); 
            message = message.replace(mo.group(), '<EMAIL>');
        }

        // Mask Phone 
        String regexPhone = '((?:\\+|00)[17](?: |\\-)?|(?:\\+|00)[1-9]\\d{0,2}(?: |\\-)?|(?:\\+|00)1\\-\\d{3}(?: |\\-)?)?(0\\d|\\([0-9]{3}\\)|[1-9]{0,3})(?:((?: |\\-)[0-9]{2}){4}|((?:[0-9]{2}){4})|((?: |\\-)[0-9]{3}(?: |\\-)[0-9]{4})|([0-9]{7}))';

        Pattern p2 = Pattern.compile(regexPhone); 
        Matcher mo2 = p2.matcher(message); 
        while (mo2.find()) { 
            System.debug(mo2.group()); 
            message = message.replace(mo2.group(), '<PHONE>');
        }
        return message;
    }

    public static UAI_BotResponse__c logResponse(Id caseId, String type, String botId, Integer statusCode, String request, String response){

        UAI_BotResponse__c botResponse = new  UAI_BotResponse__c(
            CaseId__c = caseId,
            Type__c = type,
            BotId__c = botId,
            StatusCode__c = statusCode,
            Response__c = response,
            Request__c = request
        );
        insert botResponse;
        return botResponse;
    }

    public static UAI_ProcessedCase processCaseFields(Id caseId, UAI_BotResponse firstBotResponse){
        
        UAI_ProcessedCase processedCase = new UAI_ProcessedCase();
        sObject caseObject = Schema.getGlobalDescribe().get('Case').newSObject() ;
        sObject chatTranscript;
        caseObject.put('Id', caseId);
        
        Map<String, Map<String, String>> sObjectFieldMap = new Map<String, Map<String, String>>();
        
        for(UAI_BotResponse.SFParams sfParam : firstBotResponse.salesforceObjectParameters){
            String sObjectType = sfParam.target;
            String fieldValue = sfParam.value;
            String fieldName = sfParam.key;

            if(sObjectFieldMap.get(sObjectType) == null){
                sObjectFieldMap.put(sObjectType, new Map<String, String>());
            }
            sObjectFieldMap.get(sObjectType).put(fieldName.toLowerCase(), fieldValue);
        }

        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();

        List<String> partialErrors = new List<String>();

        for(String sObjectType: sObjectFieldMap.keyset()){
            if(schemaMap.keySet().contains(sObjectType)){
                Map<String, Schema.SObjectField> fieldMap = schemaMap.get(sObjectType).getDescribe().fields.getMap();
                if(sObjectType == 'case' ){
                    for(String fieldName : sObjectFieldMap.get(sObjectType).keyset()){
                        if(fieldMap.get(fieldName) != null && fieldMap.get(fieldName).getDescribe().isUpdateable() ){
                            try{
                                caseObject.put(fieldName,convertField(sObjectType, fieldName, sObjectFieldMap.get(sObjectType).get(fieldName)));
                            }catch(Exception e){
                                partialErrors.add('sObjectType:' + sObjectType + ' FieldName:' + fieldName + ' Exception:' + e.getMessage());
                            }
                        }else if(fieldMap.get(fieldName) != null){
                            partialErrors.add(String.format(System.label.UAI_FIELD_NOT_UPDATABLE, new List<String>{fieldName}));
                        }else{
                            partialErrors.add(String.format(System.label.UAI_FIELD_NOT_VALID, new List<String>{fieldName}));
                        }
                    }
                }else if(sObjectType == 'livechattranscript' && UAI_UtilREST.doObjectExist('livechattranscript')){

                    // Query LiveChatTranscript

                    String queryLiveChatTranscript = 'SELECT Id FROM LiveChatTranscript';
                    queryLiveChatTranscript +=' WHERE CaseId =\'' + caseId + '\' ORDER BY CreatedDate DESC LIMIT 1';

                    List<sObject> chatTranscripts = Database.query(queryLiveChatTranscript);

                    if(chatTranscripts.size()==0){
                        partialErrors.add(System.label.UAI_CHAT_TRANSCRIPT_DOES_NOT_EXIST);
                    }else{
                        chatTranscript = (SObject)chatTranscripts.get(0);
                        for(String fieldName : sObjectFieldMap.get(sObjectType).keyset()){
                            if(fieldMap.get(fieldName) != null && fieldMap.get(fieldName).getDescribe().isUpdateable() ){
                                try{
                                    chatTranscript.put(fieldName, convertField(sObjectType,fieldName, sObjectFieldMap.get(sObjectType).get(fieldName)));
                                }catch(Exception e){
                                    partialErrors.add('sObjectType:' + sObjectType + ' FieldName:' + fieldName + ' Exception:' + e.getMessage());
                                }
                            }else if(fieldMap.get(fieldName) != null){
                                partialErrors.add(String.format(System.label.UAI_FIELD_NOT_UPDATABLE, new List<String>{fieldName}));
                            }else{
                                partialErrors.add(String.format(System.label.UAI_FIELD_NOT_VALID, new List<String>{fieldName}));
                            }
                        }
                    }
                }
            }else{ 
                partialErrors.add(String.format(System.label.UAI_SOBJECT_NOT_VALID, new List<String>{sObjectType}));
            }
        } 

        processedCase.record = caseObject;
        processedCase.partialErrors = partialErrors;
        if(chatTranscript != null){
            processedCase.chatTranscript = chatTranscript;
        } 

        return processedCase;
    }

    public static Object convertField(String sObjectType, String fieldName, String value){
        
        // Get the describe for the object
        DescribeSObjectResult objResult = Schema.getGlobalDescribe().get(sObjectType).getDescribe();
        // Get the field dynamically
        DescribeFieldResult fieldResult = objResult.fields.getMap().get(fieldName).getDescribe();
        Schema.DisplayType displayType = fieldResult.getType();

        if( displayType == Schema.DisplayType.BOOLEAN){
            return Boolean.valueOf(value);
        }else if(displayType == Schema.DisplayType.CURRENCY 
                || displayType == Schema.DisplayType.DOUBLE 
                || displayType == Schema.DisplayType.PERCENT){
            return Decimal.valueOf(value);
        }else if(displayType == Schema.DisplayType.INTEGER 
                || displayType == Schema.DisplayType.LONG ){
            return Integer.valueOf(value);
        }else if(displayType == Schema.DisplayType.DATE  ){
            return Date.parse(value);
        }else if(displayType == Schema.DisplayType.DATETIME  ){
            return Datetime.valueOf(value.replace('T',' '));
        }else {
            return value;
        }    
    }

}