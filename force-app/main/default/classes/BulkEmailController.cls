public with sharing class BulkEmailController {
  @AuraEnabled(cacheable=true)
  public static List<Account> getAccountsByIds(List<Id> recordIds) {
    return [SELECT Id, Email__c FROM Account WHERE Id IN :recordIds];
  }

  @AuraEnabled
  public static void sendBulkEmail(
    List<String> toAddresses, // Already a List of email addresses from LWC input
    List<String> ccAddresses, // Already a List of CC addresses
    List<String> bccAddresses, // Already a List of BCC addresses
    String subject, // Email subject from LWC
    String body, // Email body from LWC
    List<String> contentDocumentIds
  ) {
    // Optional attachments
    List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

    // Create the email message
    Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();

    // Set To addresses directly
    email.setToAddresses(toAddresses);

    // Set CC addresses if provided
    if (ccAddresses != null && !ccAddresses.isEmpty()) {
      email.setCcAddresses(ccAddresses); // No need to split, passed as list
    }

    // Set BCC addresses if provided
    if (bccAddresses != null && !bccAddresses.isEmpty()) {
      email.setBccAddresses(bccAddresses); // No need to split, passed as list
    }

    // Set subject and body
    email.setSubject(subject);
    email.setHtmlBody(body);

    // Attach files if provided
    if (contentDocumentIds != null && !contentDocumentIds.isEmpty()) {
      List<Messaging.EmailFileAttachment> attachments = new List<Messaging.EmailFileAttachment>();
      for (String contentDocumentId : contentDocumentIds) {
        try {
          ContentVersion contentVersion = [
            SELECT VersionData, Title
            FROM ContentVersion
            WHERE ContentDocumentId = :contentDocumentId
            LIMIT 1
          ];
          Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
          attachment.setFileName(contentVersion.Title);
          attachment.setBody(contentVersion.VersionData);
          attachments.add(attachment);
        } catch (Exception ex) {
          System.debug('Error retrieving content document: ' + ex.getMessage());
        }
      }
      email.setFileAttachments(attachments);
    }

    // Add the email to the list
    emails.add(email);

    // Send the email
    try {
      Messaging.sendEmail(emails);
    } catch (Exception e) {
      System.debug('Error sending emails: ' + e.getMessage());
      throw new AuraHandledException(
        'Failed to send emails: ' + e.getMessage()
      );
    }
  }
}
