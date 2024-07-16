import { LightningElement, api } from "lwc";

export default class PostToLinkedInModal extends LightningElement {
  @api message;

  closeModal() {
    this.dispatchEvent(new CustomEvent("close"));
  }

  postMessage() {
    this.dispatchEvent(new CustomEvent("post"));
  }
}
