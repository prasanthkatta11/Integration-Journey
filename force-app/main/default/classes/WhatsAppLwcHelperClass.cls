public with sharing class WhatsAppLwcHelperClass {
  @AuraEnabled
  public static List<WhatsApp_Message__c> listAllMessages(
    String customerPhone
  ) {
    List<WhatsApp_Message__c> allMessages = new List<WhatsApp_Message__c>();
    try {
      if (String.isEmpty(customerPhone)) {
        throw new AuraHandledException(
          'Customer phone number cannot be null or empty.'
        );
      }
      allMessages = [
        SELECT
          Id,
          Name,
          Message_Content__c,
          Message_Type__c,
          Customer_Name__c,
          Customer_Phone__c,
          Agent_Name__c,
          Outgoing__c,
          Message_Sent_Time__c,
          CreatedDate
        FROM WhatsApp_Message__c
        WHERE Customer_Phone__c = :customerPhone
        ORDER BY CreatedDate ASC
      ];
      return allMessages;
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  @AuraEnabled
  public static WhatsApp_Message__c sendTextMessage(
    String messageContent,
    String toPhoneNumber
  ) {
    WhatsApp_Message__c message = WhatsAppCallOut.sendTextMessage(
      messageContent,
      toPhoneNumber
    );
    try {
      if (String.isEmpty(messageContent) || String.isEmpty(toPhoneNumber)) {
        throw new AuraHandledException(
          'Message content and phone number cannot be null or empty.'
        );
      }
      return [
        SELECT
          Id,
          Name,
          Message_Content__c,
          Message_Type__c,
          Customer_Name__c,
          Customer_Phone__c,
          Agent_Name__c,
          Outgoing__c,
          Message_Sent_Time__c,
          CreatedDate
        FROM WhatsApp_Message__c
        WHERE Id = :message.Id
        ORDER BY CreatedDate ASC
      ];
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  @AuraEnabled
  public static WhatsApp_Message__c getIncomingMessage(
    String recordId,
    String customerPhone
  ) {
    try {
      if (String.isEmpty(recordId) || String.isEmpty(customerPhone)) {
        throw new AuraHandledException(
          'Record ID and customer phone number cannot be null or empty.'
        );
      }
      return [
        SELECT
          Id,
          Name,
          Message_Content__c,
          Message_Type__c,
          Customer_Name__c,
          Customer_Phone__c,
          Agent_Name__c,
          Outgoing__c,
          Message_Sent_Time__c,
          CreatedDate
        FROM WhatsApp_Message__c
        WHERE Id = :recordId AND Customer_Phone__c = :customerPhone
        ORDER BY CreatedDate ASC
      ];
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  @AuraEnabled
  public static SObject getCustomerPhoneDynamically(String query) {
    try {
      if (String.isEmpty(query)) {
        throw new AuraHandledException('Query cannot be null or empty.');
      }
      return Database.query(query);
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }
}
