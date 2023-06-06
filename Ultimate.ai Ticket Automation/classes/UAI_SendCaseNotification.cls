public without sharing class UAI_SendCaseNotification {

    @InvocableMethod(label='Case Notification Ultimate AI' description='Sends new Case Notification to UAI')
    public static List<SEActionRes> sendTextMessages(List<SEActionReq> requests){
        List<SEActionRes> results = new List<SEActionRes>();

        
        for(SEActionReq request : requests){
            UAI_CaseUtils.processBotRequest(request.caseId,  request.type, request.botId, request.subject, request.body);
            results.add(new SEActionRes(request.caseId, request.botId));
        } 
        return results;     
    }   
    

    public class SEActionReq{
        @InvocableVariable(label='Case Id' description='Case Id' required=true)
        public Id caseId;
        
        @InvocableVariable(label='Bot Id' description='Bot Id' required=true)
        public String botId;

        @InvocableVariable(label='Subject' description='Subject' required=true)
        public String subject;

        @InvocableVariable(label='Body' description='Body' required=true)
        public String body;

        @InvocableVariable(label='Case Source' description='Case Source (Email / Web-to-Case)' required=true)
        public String type;

    }

    public class SEActionRes{
        @InvocableVariable(label='Case Id' description='Case Id')
        public String caseId;

        @InvocableVariable(label='Bot Id' description='Bot Id')
        public String botId;

        public SEActionRes(){}
        public SEActionRes(String caseId, String botId){
            this.caseId = caseId;
            this.botId = botId;
        }
    }

}