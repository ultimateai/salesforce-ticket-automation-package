public without sharing class UAI_UtilREST {

    public static final String BOT_ENDPOINT = 'https://chat.ultimate.ai/salesforce/ticket/converse';
    public static final String ERROR_ENDPOINT = 'https://chat.ultimate.ai/salesforce/ticket/error';

    public static UAI_AppSetting__c setting{
        get{
            if(setting == null){
                for(UAI_AppSetting__c sett : [SELECT Id, User__c, Pass__c,EnableMasking__c FROM UAI_AppSetting__c LIMIT 1]){
                    setting = sett;
                }
            }
            return setting;  
        }set;
    }


    public static HttpResponse doCallout( String mode, String body ){
            
        CalloutResponse cResp = new CalloutResponse();

        UAI_AppSetting__c appSetting = setting;
        
        // This can be extended in order to manage multiple usernames
        if(appSetting == null){
            throw new CalloutCustomException('Setting recording missing');
        }
        
        HttpRequest req = new HttpRequest();

        req.setEndpoint( mode == 'Bot' ? BOT_ENDPOINT : ERROR_ENDPOINT);
        req.setMethod('POST');
        req.setTimeout(120000);
        req.setBody(body);   
 
        Blob headerValue = Blob.valueOf(appSetting.User__c + ':' + appSetting.Pass__c);
        req.setHeader('Authorization', 'Basic ' + EncodingUtil.base64Encode(headerValue));
        req.setHeader('Content-Type', 'application/json');

        HttpResponse response = new HTTP().send(req);   
        return response; 
            
    }

    public static boolean doObjectExist(String objectNameParam){
        for (Schema.SObjectType sObjectType : Schema.getGlobalDescribe().values() ) {
           String sobjName = String.valueOf(sObjectType);
           if (sobjName.contains(objectNameParam) ) {
               return true;
           }
        }
        return false;
    }

    public class CalloutResponse{
        public Integer statusCode;
        public String error;
        public CalloutResponse(){

        }
        public CalloutResponse(Integer statusCode, String error){
            this.statusCode = statusCode;
            this.error = error;
        }
    } 

    
    public class CalloutCustomException extends Exception {}


}