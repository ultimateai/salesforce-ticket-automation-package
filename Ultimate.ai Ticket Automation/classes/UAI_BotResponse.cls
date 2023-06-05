public class UAI_BotResponse {

    public List<Message> messages {get;set;}
    public List<PredictedIntent> predictedIntents {get;set;}
    public List<SFParams> salesforceObjectParameters {get;set;}

    public class PredictedIntent{
        public String name {get;set;}
        public String value {get;set;}
        public Decimal confidence {get;set;}
    }

    public class Message{
        public String text {get;set;}
    }

    public class SFParams{
        public String key {get;set;}
        public String value {get;set;}
        public String target {get;set;}
    }
}