public without sharing class WhatsAppCallOut {
  public static WhatsApp_Message__c sendTextMessage(
    String messageContent,
    String toPhoneNumber
  ) {
    HttpRequest req = new HttpRequest();

    //req.setEndpoint(
    //   'callout:WhatsApp_Named_Cred/v20.0/293709137162139/messages'
    // );
    req.setEndpoint(
      'https://graph.facebook.com/v20.0/293709137162139/messages'
    );
    req.setMethod('POST');
    req.setHeader(
      'Authorization',
      'Bearer ' + System.label.WHATSAPPACCESSTOKEN
    );
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
    WhatsApp_Message__c salesforceMessage = new WhatsApp_Message__c();

    try {
      HttpResponse res = http.send(req);
      if (res.getStatusCode() == 200) {
        WhatsAppCallOut whatsappResponse = (WhatsAppCallOut) JSON.deserialize(
          res.getBody(),
          WhatsAppCallOut.class
        );

        salesforceMessage.Message_ID__c = whatsappResponse.messages[0].id;
        salesforceMessage.Message_Type__c = 'text';
        salesforceMessage.Message_Sent_Time__c = System.now();
        salesforceMessage.Message_Content__c = messageContent;
        salesforceMessage.Customer_Phone__c = toPhoneNumber;
        salesforceMessage.Outgoing__c = true;
        salesforceMessage.Agent_Name__c =
          UserInfo.getFirstName() +
          ' ' +
          UserInfo.getLastName();

        upsert salesforceMessage Message_ID__c;
        System.debug(
          'Salesforce message created or updated: ' + salesforceMessage
        );
      } else {
        System.debug('HTTP Response Status Code: ' + res.getStatusCode());
        System.debug('Response Body: ' + res.getBody());
      }
    } catch (System.CalloutException e) {
      System.debug('Callout Exception: ' + e.getMessage());
      System.debug(
        'Callout Executed ' + e.getStackTraceString() + ' ' + e.getLineNumber()
      );
    } catch (Exception e) {
      System.debug('General Exception: ' + e.getMessage());
      System.debug(
        'Exception Executed ' +
          e.getStackTraceString() +
          ' ' +
          e.getLineNumber()
      );
    }
    return salesforceMessage;
  }

  public static String getMediaUrl(String mediaId) {
    HttpRequest req = new HttpRequest();
    req.setEndpoint(
      'https://graph.facebook.com/v20.0/' +
        mediaId +
        '?phone_number_id=293709137162139'
    );
    req.setMethod('GET');
    req.setHeader(
      'Authorization',
      'Bearer ' + System.label.WHATSAPPACCESSTOKEN
    );
    req.setHeader('Content-Type', 'application/json');

    Http http = new Http();
    HttpResponse res = http.send(req);

    if (res.getStatusCode() == 200) {
      Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(
        res.getBody()
      );
      string url = (String) result.get('url');
      System.debug('URL: ' + url); // Debugging URL output
      return url;
    } else {
      System.debug('Failed to retrieve media URL: ' + res.getBody());
      return null;
    }
  }

  public static void saveDocumentToSalesforce(String mediaId, Id recordId) {
    String mediaUrl = getMediaUrl(mediaId);

    // String protocol = mediaUrl.substring(0, mediaUrl.indexOf('://') + 3);
    // String mediaUrlWithoutProtocol = mediaUrl.substring(
    //   mediaUrl.indexOf('://') + 3
    // );
    // String mediaHost = mediaUrlWithoutProtocol.substring(
    //   0,
    //   mediaUrlWithoutProtocol.indexOf('/')
    // );
    // System.debug('Host: ' + mediaHost);

    // String mediaPath = mediaUrlWithoutProtocol.substring(
    //   mediaUrlWithoutProtocol.indexOf('/'),
    //   mediaUrlWithoutProtocol.indexOf('?')
    // );
    // System.debug('Path: ' + mediaPath);

    // String mediaQuery = mediaUrlWithoutProtocol.substring(
    //   mediaUrlWithoutProtocol.indexOf('?') + 1
    // );
    // System.debug('Query: ' + mediaQuery);

    // if (mediaUrl == null) {
    //   System.debug('Failed to get media URL for document ID: ' + mediaId);
    //   return;
    // }

    // if (mediaHost == 'lookaside.fbsbx.com') {
    //   HttpRequest req = new HttpRequest();
    //   req.setEndpoint(
    //     'callout:WhatsApp_MediaURL_Named_Cred' + mediaPath + '?' + mediaQuery
    //   );
    HttpRequest req = new HttpRequest();
    req.setMethod('GET');
    req.setEndpoint(mediaUrl);
    req.setHeader(
      'Authorization',
      'Bearer ' + System.label.WHATSAPPACCESSTOKEN
    );
    req.setHeader('Content-Type', 'application/json');

    Http http = new Http();
    HttpResponse res = http.send(req);

    if (res.getStatusCode() == 200) {
      ContentVersion cv = new ContentVersion();
      cv.Title = 'WhatsApp Document';
      cv.PathOnClient = 'WhatsApp_Document';
      cv.VersionData = res.getBodyAsBlob();
      cv.Origin = 'H';
      cv.ContentLocation = 'S';
      insert cv;

      // Query ContentDocumentId from the inserted ContentVersion
      ContentVersion insertedCv = [
        SELECT ContentDocumentId
        FROM ContentVersion
        WHERE Id = :cv.Id
        WITH SECURITY_ENFORCED
        LIMIT 1
      ];

      if (insertedCv.ContentDocumentId != null) {
        // Create ContentDocumentLink to link ContentDocument to the record
        ContentDocumentLink link = new ContentDocumentLink();
        link.ContentDocumentId = insertedCv.ContentDocumentId;
        link.LinkedEntityId = recordId;
        link.ShareType = 'V';
        insert link;
      } else {
        System.debug(
          'ContentDocumentId is null for ContentVersion Id: ' + cv.Id
        );
      }
    } else {
      System.debug('Failed to download document: ' + res.getBody());
    }
    //}
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
