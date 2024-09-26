import { LightningElement, api } from "lwc";
import { FlowAttributeChangeEvent } from "lightning/flowSupport";

export default class RichTextEditor extends LightningElement {
  // Public property from flow
  @api varbody = "";

  // Private property used within the component
  localBody = "";

  // When the component is initialized, set the localBody with the public body
  connectedCallback() {
    this.localBody = this.varbody;
  }

  // Handle changes in the rich text input
  handleBodyChange(event) {
    this.localBody = event.target.value;

    // Dispatch a FlowAttributeChangeEvent to pass the updated body back to the flow
    this.dispatchEvent(new FlowAttributeChangeEvent("varbody", this.localBody));
  }
}
