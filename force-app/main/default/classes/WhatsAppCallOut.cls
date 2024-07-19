public with sharing class WhatsAppCallOut {
  public static Void sendTextMessage(
    String messageContent,
    String toPhoneNumber
  ) {
    HttpRequest req = new HttpRequest();

    req.setEndpoint(
      'callout:WhatsApp_Named_Cred/v20.0/293709137162139/messages'
    );
    req.setMethod('POST');
    req.setHeader('Content-Type', 'application/json');

    String jsonBody =
      '{' +
      '    "messaging_product": "whatsapp", ' +
      '    "recipient_type": "individual", ' +
      '    "to": "{{Recipient-Phone-Number}}", ' +
      '    "type": "text", ' +
      '    "text": { ' +
      '        "preview_url": false, ' +
      '        "body": "{{Body}}" ' +
      '    } ' +
      '} ';
    jsonBody = jsonBody.replace('{{Recipient-Phone-Number}}', toPhoneNumber);
    jsonBody = jsonBody.replace('{{Body}}', messageContent);
    req.setBody(jsonBody);

    Http http = new Http();

    try {
      HttpResponse res = http.send(req);
      if (res.getStatusCode() == 200) {
        WhatsAppCallOut whatsappResponse = (WhatsAppCallOut) JSON.deserialize(
          res.getBody(),
          WhatsAppCallOut.class
        );

        //Create Record
        WhatsApp_Message__c salesforceMessage = new WhatsApp_Message__c();

        salesforceMessage.Message_ID__c = whatsappResponse.messages[0].id;
        salesforceMessage.Message_Type__c = 'text';
        salesforceMessage.Message_Sent_Time__c = System.now();
        salesforceMessage.Message_Content__c = messageContent;
        salesforceMessage.Customer_Phone__c = toPhoneNumber;

        upsert salesforceMessage;
      }
    } catch (System.CalloutException e) {
      System.debug(
        'Callout Executed ' + e.getStackTraceString() + ' ' + e.getLineNumber()
      );
    } catch (Exception e) {
      System.debug(
        'Exception Executed ' +
          e.getStackTraceString() +
          ' ' +
          e.getLineNumber()
      );
    }
  }

  public String messaging_product;
  public contacts[] contacts;
  public messages[] messages;
  public class contacts {
    public String input;
    public String wa_id;
  }
  public class messages {
    public String id;
  }
}
