public class UAI_ErrorLogRequest {
    public String botId {get;set;}
    public String conversationId {get;set;}
    public String errorMessage {get;set;}

    public UAI_ErrorLogRequest( String botId, String conversationId, String errorMessage ){
        this.botId = botId;
        this.errorMessage = errorMessage;
        this.conversationId = conversationId;
    }
}