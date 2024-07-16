import { LightningElement } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import POSTTOLINKEDIN from "@salesforce/apex/LinkedInIntegration.postToLinkedIn";

export default class PostToLinkedInComponent extends LightningElement {
  message = "";
  showError = false;
  textareaClass = "";
  isModalOpen = false;

  handleMessageChange(event) {
    this.message = event.target.value;
    this.showError = false;
    this.textareaClass = "";
  }

  handlePost() {
    if (!this.message.trim()) {
      this.showError = true;
      this.textareaClass = "slds-has-error";
      return;
    }
    this.isModalOpen = true;
  }

  handleModalClose() {
    this.isModalOpen = false;
  }

  async handleModalPost() {
    this.isModalOpen = false;
    try {
      const result = await POSTTOLINKEDIN({ message: this.message });
      this.message = "";
      this.showToast(
        "Success",
        "Your message has been posted to LinkedIn.",
        "success",
        "sticky"
      );
      console.log(
        "🚀 ~ PostToLinkedInComponent ~ handlePost ~ result:",
        result
      );
    } catch (error) {
      this.showToast(
        "Error",
        "There was an error posting to LinkedIn.",
        "error",
        "sticky"
      );
    }
  }
  showToast(title, message, variant, mode) {
    const event = new ShowToastEvent({
      title: title,
      message: message,
      variant: variant,
      mode: mode
    });
    this.dispatchEvent(event);
  }
}
