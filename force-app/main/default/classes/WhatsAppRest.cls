@RestResource(urlMapping='/whatsapp/webhooks/v1/*')
global without sharing class WhatsAppRest {
  @HttpGet
  global static void doGet() {
    //The request that is sent from WhatsApp to Salesforce with headers in GET METHOD
    RestRequest request = RestContext.request;
    System.debug('doGet ' + request);
    //The response that is sent from Salesforce to WhatsApp with headers required value for WhatsApp in GET METHOD
    RestResponse response = RestContext.response;
    System.debug('doGet ' + response);
    if (
      request.params.get('hub.verify_token') == System.label.WHATSVERIFYTOKEN
    ) {
      String hubChallenge = request.params.get('hub.challenge');
      response.responseBody = Blob.valueOf(request.params.get('hub.challenge'));
      System.debug('doGet ' + hubChallenge);
    }
  }

  @HttpPost
  global static void doPost() {
    //The response that needs to be sent back to WhatsApp either Successful or failure
    RestResponse response = RestContext.response;
    System.debug('doPost ' + response);
    //Response that needs to be sent back to WhatsApp should be in JSON format
    response.addHeader('Content-Type', 'application/json');
    //Request the body that is received from WhatsApp into a variable of type string
    String responseString = RestContext.request.requestBody.toString();
    System.debug('doPost ' + responseString);
    //Additional headers thet we request from the WhatsApp-request should be in a Map format of key value pair
    //Ex: X-Hub-Signature-256: sha256={super-long-SHA256-signature}
    Map<String, String> headers = RestContext.request.headers;
    System.debug('doPost ' + headers);
    //Validate the signature of the request from WhatsApp by decrypting the
    //SHA-256 signature with the secret value of the WhatsApp integration
    //and then comparing the response string from the request with
    //the response string from the JSON body of the request
    //If the signature is valid then the request is sent to the method
    //If the signature is invalid then the request is not processed and
    //the response is sent back to WhatsApp with the status code 401
    //Passing parameters for validateHubSignature as RestContext.request which is nothing but the Restrequest
    //and the response string from the request body of the request
    String responseValid = validateHubSignature(
      RestContext.request,
      responseString
    );
    System.debug('doPost ' + responseValid);

    if (responseValid == 'Valid') {
      System.debug(
        System.LoggingLevel.DEBUG,
        'Headers response from WhatsApp: ' + JSON.serialize(headers)
      );

      System.debug(
        System.LoggingLevel.DEBUG,
        'Body response from WhatsApp: ' + responseString
      );

      String finalResponseString = responseString.replace('type', 'typex');
      System.debug('doPost ' + finalResponseString);

      WhatsAppRestWrapperClass parentMessage = (WhatsAppRestWrapperClass) JSON.deserialize(
        finalResponseString,
        WhatsAppRestWrapperClass.class
      );
      System.debug('doPost ' + parentMessage);

      List<WhatsAppRestWrapperClass.entry> messageEntries = parentMessage.entry;
      if (messageEntries != null && messageEntries.size() > 0) {
        WhatsAppRestWrapperClass.entry entryMessage = messageEntries.get(0);
        List<WhatsAppRestWrapperClass.changes> changeMessages = entryMessage.changes;
        if (changeMessages != null && changeMessages.size() > 0) {
          WhatsAppRestWrapperClass.changes changeMessage = changeMessages.get(
            0
          );
          List<WhatsAppRestWrapperClass.contacts> contactList = changeMessage.value.contacts;
          List<WhatsAppRestWrapperClass.messages> messageList = changeMessage.value.messages;
          WhatsAppRestWrapperClass.metadata metadata = changeMessage.value.metadata;

          //Create Record in Salesforce
          WhatsApp_Message__c salesforceMessage = new WhatsApp_Message__c();
          salesforceMessage.Business_Phone_Number__c = metadata != null
            ? metadata.display_phone_number
            : null;

          if (contactList != null && contactList.size() > 0) {
            WhatsAppRestWrapperClass.contacts contact = contactList.get(0);
            salesforceMessage.Customer_Phone__c = contact.wa_id;
            salesforceMessage.Customer_Name__c = contact.profile.name;
          }

          if (messageList != null && messageList.size() > 0) {
            //Just a text Message
            WhatsAppRestWrapperClass.messages message = messageList.get(0);
            salesforceMessage.Message_ID__c = message.id;
            salesforceMessage.Message_Type__c = message.typex;
            salesforceMessage.Message_Sent_Time__c = System.now();
            salesforceMessage.Message_Content__c = message.text != null
              ? message.text.body
              : null;

            //If message is Image
            salesforceMessage.Image_ID__c = message.image != null
              ? message.image.id
              : null;
            salesforceMessage.Image_Type__c = message.image != null
              ? message.image.mime_typex
              : null;
            salesforceMessage.Image_SHA256__c = message.image != null
              ? message.image.sha256
              : null;

            // If message is a reaction
            salesforceMessage.Reaction__c = message.reaction != null &&
              message.typex == 'reaction'
              ? message.reaction.emoji
              : null;
            salesforceMessage.Parent_Message_ID__c = message.reaction != null &&
              message.typex == 'reaction'
              ? message.reaction.message_id
              : salesforceMessage.Parent_Message_ID__c;

            // If message is a document
            salesforceMessage.Document_ID__c = message.document != null
              ? message.document.id
              : null;
            salesforceMessage.Document_Type__c = message.document != null
              ? message.document.mime_typex
              : null;
            salesforceMessage.Document_SHA256__c = message.document != null
              ? message.document.sha256
              : null;
            salesforceMessage.Document_Filename__c = message.document != null
              ? message.document.filename
              : null;

            String mediaId = message.document != null
              ? message.document.id
              : null;

            // If the message is a reply to another message
            salesforceMessage.Parent_Message_ID__c = message.context != null
              ? message.context.id
              : salesforceMessage.Parent_Message_ID__c;

            System.debug('Parent ID ' + salesforceMessage.Parent_Message_ID__c);

            upsert salesforceMessage Message_ID__c;

            if (message.document != null) {
              WhatsApp_Media_Event__e mediaEvent = new WhatsApp_Media_Event__e();
              mediaEvent.MediaId__c = message.document.id;
              mediaEvent.RecordId__c = salesforceMessage.Id;
              mediaEvent.Customer_Phone_Number__c = null;
              Database.SaveResult sr = EventBus.publish(mediaEvent);

              if (sr.isSuccess()) {
                System.debug('Event published successfully: ' + sr.getId());
              } else {
                System.debug(
                  'Failed to publish event: ' + sr.getErrors()[0].getMessage()
                );
              }
            } else {
              // When the document is not present, still publish an event with different or minimal details
              WhatsApp_Media_Event__e mediaEvent = new WhatsApp_Media_Event__e();
              mediaEvent.MediaId__c = null; // Explicitly set to null or some placeholder if needed
              mediaEvent.RecordId__c = salesforceMessage.Id;
              mediaEvent.Customer_Phone_Number__c = salesforceMessage.Customer_Phone__c;
              Database.SaveResult sr = EventBus.publish(mediaEvent);

              if (sr.isSuccess()) {
                System.debug('Event published successfully: ' + sr.getId());
              } else {
                System.debug(
                  'Failed to publish event: ' + sr.getErrors()[0].getMessage()
                );
              }
            }
          }
        }
      } else {
        response.responseBody = Blob.valueOf(
          '{success:false, event:"Unknown", "message:"' + responseValid + '"}'
        );
        response.statusCode = 401;
        return;
      }

      response.statusCode = 200;
      response.responseBody = Blob.valueOf('{success:true, event:"success"}');
    }
  }

  private static String validateHubSignature(
    RestRequest request,
    String responseString
  ) {
    Map<String, String> headers = request.headers;

    String hubSignature = headers.get('X-Hub-Signature-256');

    String whatsAppPayLoad = RestContext.request.requestBody.toString();

    String whatsAppSecret = System.Label.WHATSAPPSECRET;
    Blob signedPayLoad = Crypto.generateMac(
      'HmacSHA256',
      Blob.valueOf(whatsAppPayLoad),
      Blob.valueOf(whatsAppSecret)
    );

    String encodedPayLoad =
      'SHA256=' + EncodingUtil.convertToHex(signedPayLoad);

    return (encodedPayLoad == hubSignature) ? 'Valid' : 'Invalid Signature';
  }
}
