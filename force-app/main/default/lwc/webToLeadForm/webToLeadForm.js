import { LightningElement, wire } from "lwc";
import LEAD_OBJECT from "@salesforce/schema/Lead";
import FIRSTNAME_FIEL from "@salesforce/schema/Lead.FirstName";
import LASTNAME_FIELD from "@salesforce/schema/Lead.LastName";
import EMAIL_FIELD from "@salesforce/schema/Lead.Email";
import PHONE_FIELD from "@salesforce/schema/Lead.Phone";
import DESCRIPTION_FIELD from "@salesforce/schema/Lead.Description";
import TERMS_FIELD from "@salesforce/schema/Lead.I_agree_to_terms_and_conditions__c";
import INDUSTRY_FIELD from "@salesforce/schema/Lead.Industry";
import { getObjectInfo, getPicklistValues } from "lightning/uiObjectInfoApi";

export default class WebToLeadForm extends LightningElement {
  selectedIndustryValue = "";
  industryOptions = [];
  firstName = "";
  lastName = "";
  email = "";
  mobileNumber = "";
  description = "";
  termsAccepted = false;

  handleChange(event) {
    let field = event.target.dataset.id;
    if (field === "termsAccepted") {
      this.termsAccepted = event.target.checked;
      console.log(
        "🚀 ~ WebToLeadForm ~ handleChange ~ this.termsAccepted:",
        this.termsAccepted
      );
    } else {
      this[field] = event.target.value;
      console.log(
        "🚀 ~ WebToLeadForm ~ handleChange ~ this[field]:",
        this[field]
      );
    }
  }

  @wire(getObjectInfo, { objectApiName: LEAD_OBJECT })
  leadObjectInfo;

  @wire(getPicklistValues, {
    recordTypeId: "$leadObjectInfo.data.defaultRecordTypeId",
    fieldApiName: INDUSTRY_FIELD
  })
  industryPickList({ data, error }) {
    if (data) {
      console.log("🚀 ~ WebToLeadForm ~ industryPickList ~ data:", data);
      this.industryOptions = data.values;
    } else if (error) {
      console.log("🚀 ~ WebToLeadForm ~ industryPickList ~ error:", error);
    }
  }
}
