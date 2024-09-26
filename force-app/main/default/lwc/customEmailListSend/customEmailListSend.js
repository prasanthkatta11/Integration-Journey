import { LightningElement, api, track, wire } from "lwc";
import sendBulkEmail from "@salesforce/apex/BulkEmailController.sendBulkEmail"; // Import the method to fetch email addresses
import accountByIds from "@salesforce/apex/BulkEmailController.getAccountsByIds";
import EMAIL_FIELD from "@salesforce/schema/Account.Email__c";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { NavigationMixin } from "lightning/navigation";

export default class CustomEmailListSend extends NavigationMixin(
  LightningElement
) {
  @api recordIds; // Public property to receive the recordIds passed from the Flow button URL
  @track toAddresses = [];
  @track ccAddresses = [];
  @track bccAddresses = [];
  @track subject = "";
  @track body = "";
  @track contentDocumentIds = [];

  //To test if the recordIds are available at initialising of the component
  // connectedCallback() {
  //   console.log("Connected Callback: Record IDs:", this.recordIds);
  // }

  // //To see if records are selected and then process the proxy object from flow
  // renderedCallback() {
  //   console.log("Rendered Callback: Record IDs:", this.recordIds);
  //   if (this.recordIds && this.recordIds.length > 0) {
  //     this.processRecordIds();
  //   }
  // }

  // //Proxy object is coverted to array to pass into wire adapter
  // processRecordIds() {
  //   // Convert Proxy object to regular array
  //   const regularArray = Array.from(this.recordIds);
  //   console.log("Regular Array of Record IDs:", regularArray);
  //   this.formattedRecordIds = regularArray;
  // }

  @wire(accountByIds, { recordIds: "$recordIds" })
  wiredRecords({ error, data }) {
    console.log("Record IDs:", this.recordIds);
    console.log("Data from getRecords:", data);
    console.log("Error from getRecords:", error);
    if (data) {
      this.toAddresses = data
        .map((account) => account[EMAIL_FIELD.fieldApiName])
        .join(", ");
    } else if (error) {
      this.dispatchEvent(
        new ShowToastEvent({
          title: "Error fetching emails",
          message: error.body.message,
          variant: "error"
        })
      );
    }
  }

  handlechange(event) {
    let { name, value } = event.target;
    this[name] = value;
    console.log("🚀 ~ handlechange ~ this[name] :", this[name]);
    if (name === "fileUploader") {
      const uploadedFiles = event.target.files;
      this.contentDocumentIds = uploadedFiles.map((file) => file.documentId);
      console.log(
        "🚀 ~ handlechange ~ this.contentDocumentIds:",
        this.contentDocumentIds
      );
    }
  }

  sendEmail() {
    sendBulkEmail({
      toAddresses: this.toAddresses,
      ccAddresses: this.ccAddresses,
      bccAddresses: this.bccAddresses,
      subject: this.subject,
      body: this.body,
      contentDocumentIds: this.contentDocumentIds
    })
      .then(() => {
        this.dispatchEvent(
          new ShowToastEvent({
            title: "Success",
            message: "Emails sent successfully!",
            variant: "success"
          })
        );
        this.resetFields(); // Optionally reset fields(will implement later)
      })
      .catch((error) => {
        this.dispatchEvent(
          new ShowToastEvent({
            title: "Error sending emails",
            message: error.body.message,
            variant: "error"
          })
        );
      });
  }

  closeComposer() {
    this[NavigationMixin.Navigate]({
      type: "standard__objectPage",
      attributes: {
        objectApiName: "Account",
        actionName: "list"
      },
      state: {
        filterName: "All Accounts"
      }
    });
  }
}
