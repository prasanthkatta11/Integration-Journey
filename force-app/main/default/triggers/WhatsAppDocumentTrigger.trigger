trigger WhatsAppDocumentTrigger on WhatsApp_Media_Event__e(after insert) {
  List<WhatsAppDocumentProcessor> jobs = new List<WhatsAppDocumentProcessor>();

  for (WhatsApp_Media_Event__e event : Trigger.New) {
    if (event.MediaId__c != null) {
      jobs.add(
        new WhatsAppDocumentProcessor(event.MediaId__c, event.RecordId__c)
      );
    }
  }

  if (!jobs.isEmpty()) {
    for (WhatsAppDocumentProcessor job : jobs) {
      System.enqueueJob(job);
    }
  }
}
