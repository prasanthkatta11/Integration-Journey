public class WhatsAppDocumentProcessor implements Queueable, Database.AllowsCallouts {
  private String mediaId;
  private Id recordId;

  public WhatsAppDocumentProcessor(String mediaId, Id recordId) {
    this.MediaId = mediaId;
    this.RecordId = recordId;
  }

  public void execute(QueueableContext context) {
    System.debug(
      'Queueable execute started for MediaId: ' +
        this.mediaId +
        ', RecordId: ' +
        this.recordId
    );
    WhatsAppCallOut.saveDocumentToSalesforce(this.mediaId, this.recordId);
  }
}
