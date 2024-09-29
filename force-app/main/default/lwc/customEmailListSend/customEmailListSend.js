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
  @track ccAddresses = "";
  @track bccAddresses = "";
  @track subject = "";
  @track body = "";
  @track contentDocumentIds = [];

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

  handleChange(event) {
    try {
      let { name, value } = event.target;
      this[name] = value;
      console.log(`${name} value updated: `, this[name]);
    } catch (error) {
      console.error("Error in handleChange:", error);
      this.dispatchEvent(
        new ShowToastEvent({
          title: "Error",
          message: "An error occurred while processing the input.",
          variant: "error"
        })
      );
    }
  }

  handleUploadFinished(event) {
    const uploadedFiles = event.detail.files;
    this.contentDocumentIds = uploadedFiles.map((file) => file.documentId);
    console.log("Uploaded files:", this.contentDocumentIds);
  }

  sendEmail() {
    console.log("To Addresses:", this.toAddresses);
    console.log("CC Addresses:", this.ccAddresses);
    console.log("BCC Addresses:", this.bccAddresses);
    console.log("Subject:", this.subject);
    console.log("Body:", this.body);
    console.log("Content Document IDs:", this.contentDocumentIds);

    sendBulkEmail({
      toAddresses: this.toAddresses.split(",").map((email) => email.trim()),
      ccAddresses:
        this.ccAddresses && this.ccAddresses.trim() !== ""
          ? this.ccAddresses.split(",").map((email) => email.trim())
          : [],
      bccAddresses:
        this.bccAddresses && this.bccAddresses.trim() !== ""
          ? this.ccAddresses.split(",").map((email) => email.trim())
          : [],
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

  resetFields() {
    this.toAddresses = [];
    this.ccAddresses = "";
    this.bccAddresses = "";
    this.subject = "";
    this.body = "";
    this.contentDocumentIds = [];
  }

  closeComposer() {
    this[NavigationMixin.Navigate]({
      type: "standard__objectPage",
      attributes: {
        objectApiName: "Account",
        actionName: "list"
      },
      state: {
        filterName: "AllAccounts"
      }
    });
  }
}
