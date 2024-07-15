public class LinkedInIntegration {
    
    public static String loginToLinkedIn(){
        Http http = new Http();
        
        Httprequest request = new Httprequest();
        request.setMethod('GET');
        request.setEndpoint('callout:LinkedIn_Named_Credential/v2/userinfo');
        try{
            Httpresponse response =http.send(request);
            System.debug('Response ' + response.getBody());
            if(response.getStatusCode() == 200){
                Map<String, Object> result =(Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                System.debug('Result ' + result);
                String logonId = (String)result.get('sub');
                System.debug('logonId ' + logonId);
                return logonId;
            }
        }catch(Exception ex){
            System.debug('Exception' +ex.getMessage());
        }
        return null;
    }
    
    public static void postToLinkedIn(String Message){
        String loginId =loginToLinkedIn();
        postMessageToLinkedIn(loginId, Message);
    }
    
    public static void postMessageToLinkedIn(String loginId, String Message){
        Http http = new Http();
        
        Httprequest request = new Httprequest();
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        String authorPerson = 'urn:li:person:'+loginId;
        String linkedInPostBody = 
            '{ '+
                '"author": "'+authorPerson+'", '+
                '"lifecycleState": "PUBLISHED", '+
                '"specificContent": { '+
                    '"com.linkedin.ugc.ShareContent": { '+
                        '"shareCommentary": { '+
                            '"text": "'+Message+'" '+
                        '}, '+
                        '"shareMediaCategory": "NONE" '+
                    '} '+
                '}, '+
                '"visibility": { '+
                    '"com.linkedin.ugc.MemberNetworkVisibility": "PUBLIC" '+
                '} '+
			'}';
        request.setBody(linkedInPostBody);
        request.setEndpoint('callout:LinkedIn_Named_Credential/v2/ugcPosts');
        try{
            Httpresponse response =http.send(request);
            System.debug('BodyResponse ' + response.getBody());
            System.debug('BodyResponse ' + response.getStatusCode());
        }catch(Exception ex){
            System.debug('Exception' +ex.getMessage());
        }
    }
}