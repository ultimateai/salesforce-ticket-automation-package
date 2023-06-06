public class UAI_LogErrorQueueable implements Queueable, Database.AllowsCallouts {

    private String body;

    public UAI_LogErrorQueueable(String body){
        this.body = body;
    }

    public void execute(QueueableContext context) {
        UAI_UtilREST.doCallout(UAI_CaseUtils.MODE_ERRORLOG, body);
    }
}