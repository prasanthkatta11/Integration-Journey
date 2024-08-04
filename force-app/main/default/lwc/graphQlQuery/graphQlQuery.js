import { LightningElement, wire, track } from "lwc";
import { gql, graphql } from "lightning/uiGraphQLApi";

const columns = [
  { label: "Name", fieldName: "Name", type: "text" },
  { label: "Phone", fieldName: "Phone", type: "text" },
  { label: "Email", fieldName: "Email", type: "email" },
  { label: "Account Name", fieldName: "AccountName", type: "text" },
  { label: "Annual Revenue", fieldName: "AnnualRevenue", type: "currency" },
  {
    label: "Created Date",
    fieldName: "CreatedDate",
    type: "date",
    typeAttributes: {
      day: "numeric",
      month: "short",
      year: "numeric",
      hour: "2-digit",
      minute: "2-digit",
      second: "2-digit",
      hour12: true
    },
    sortable: false
  }
];

export default class GraphQlQuery extends LightningElement {
  contacts;
  error;
  searchValue = "";
  @track isLoading = false;

  contactsList = [];
  fields = columns;
  after = null;
  pageInfo = {};
  pageNumber = 1;
  totalRecordCount = 0;
  selectedValue = "3";

  options = [
    { label: "3", value: "3" },
    { label: "5", value: "5" },
    { label: "7", value: "7" },
    { label: "10", value: "10" }
  ];

  connectedCallback() {
    this.isLoading = true;
  }

  handleSizeChange(event) {
    this.selectedValue = event.detail.value;
    this.isLoading = true;
  }

  get totalPages() {
    return Math.ceil(this.totalRecordCount / parseInt(this.selectedValue, 10));
  }

  get disableRecordSizeSelection() {
    return this.pageNumber !== 1 || !this.pageInfo.hasNextPage;
  }

  get variables() {
    console.log("Variables:", {
      searchTerm: `%${this.searchValue}%`,
      after: this.after,
      first: parseInt(this.selectedValue, 10)
    });
    return {
      searchTerm: `%${this.searchValue}%`,
      after: this.after,
      first: parseInt(this.selectedValue, 10)
    };
  }

  @wire(graphql, {
    query: gql`
      query getContacts($searchTerm: String, $after: String, $first: Int) {
        uiapi {
          query {
            Contact(
              where: { Name: { like: $searchTerm } }
              orderBy: { Name: { order: ASC } }
              after: $after
              first: $first
            ) {
              edges {
                node {
                  Id
                  Name {
                    value
                  }
                  Email {
                    value
                  }
                  Phone {
                    value
                  }
                  CreatedDate {
                    value
                    displayValue
                  }
                  Account {
                    Name {
                      value
                    }
                    Rating {
                      value
                    }
                    AnnualRevenue {
                      value
                      displayValue
                    }
                    Industry {
                      value
                      displayValue
                    }
                  }
                }
              }
              totalCount
              pageInfo {
                hasNextPage
                hasPreviousPage
                startCursor
                endCursor
              }
            }
          }
        }
      }
    `,
    variables: "$variables"
  })
  graphqlData({ data, errors }) {
    if (data) {
      console.log("uiapi all records: ", data);
      this.pageInfo = data.uiapi.query?.Contact?.pageInfo;
      this.totalRecordCount = data.uiapi.query?.Contact?.totalCount;
      this.contacts = data.uiapi.query?.Contact?.edges;
      this.contactsList = this.contacts.map((contact) => {
        // console.log("Node: ", contact);
        return {
          Id: contact.node.Id,
          Name: contact.node.Name.value,
          Phone: contact.node.Phone.value,
          Email: contact.node.Email.value,
          AccountName: contact.node.Account?.Name?.value,
          AnnualRevenue: contact.node.Account?.AnnualRevenue?.value,
          CreatedDate: contact.node.CreatedDate?.value || "N/A"
        };
      });
      this.isLoading = false;
      console.log("CreatedDate:", this.contactsList[0]?.CreatedDate);
      console.log("Processed Contacts List:", this.contactsList);
    } else if (errors) {
      console.log("GraphQL Errors:", errors);
      this.error = errors;
      this.isLoading = false;
    }
  }

  handleChange(event) {
    event.preventDefault();
    this.searchValue = event.target.value;
    this.pageNumber = 1;
    this.after = null;
    this.isLoading = true;
  }

  handleNext(event) {
    event.preventDefault();
    this.isLoading = true;
    console.log(
      "🚀 ~ GraphQlQuery ~ handleNext ~ this.pageInfo:",
      this.pageInfo
    );
    if (this.pageInfo?.hasNextPage) {
      console.log(
        "🚀 ~ GraphQlQuery ~ handleNext ~ this.pageInfo.hasNextPage:",
        this.pageInfo.hasNextPage
      );
      this.after = this.pageInfo.endCursor;
      console.log("After:", this.after);
      this.pageNumber++;
    } else {
      this.after = null;
      this.pageNumber = 1;
    }
  }

  get disableNextButton() {
    return !this.pageInfo?.hasNextPage;
  }

  handleReset(event) {
    event.preventDefault();
    this.isLoading = true;
    this.searchValue = "";
    this.pageNumber = 1;
    this.after = null;
  }
}
