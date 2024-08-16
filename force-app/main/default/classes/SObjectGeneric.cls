public with sharing class SObjectGeneric {
  public static void sObjTyp(String objectName, String recordId) {
    Schema.sObjectType sObjectv = Schema.getGlobalDescribe().get(objectName);
    System.debug('SObjectType: ' + sObjectv);
    if (sObjectv == null) {
      return;
    }
    schema.DescribeSobjectResult describeSObjResult = sObjectv.getDescribe();
    System.debug(
      'Describe Object Result for ' +
        objectName +
        ': ' +
        JSON.Serializepretty(describeSObjResult)
    );

    Map<String, schema.SObjectField> fieldMap = describeSObjResult.fields.getMap();
    System.debug(
      'Field map for ' +
        objectName +
        ': ' +
        fieldMap +
        ' and ' +
        fieldMap.size()
    );

    String query =
      'SELECT ' +
      String.join(fieldMap.keySet(), ', ') +
      ' FROM ' +
      objectName +
      ' WHERE Id = :recordId LIMIT 1';
    System.debug('Dynamic SOQL Query: ' + query);

    Sobject record = Database.query(query);
    System.debug('record: ' + record);

    Map<string, object> keyValuePair = new Map<string, object>();

    for (String fieldName : fieldMap.keyset()) {
      object fieldValue = record.get(fieldName);
      System.debug('Field Name: ' + fieldName + ', Field Value: ' + fieldValue);
      Schema.SObjectField sObjectField = fieldMap.get(fieldName);
      Schema.DescribeFieldResult fieldDescribe = sObjectField.getDescribe();
      System.debug(
        'Field Describe Result: ' + JSON.serializePretty(fieldDescribe)
      );

      String fieldLabel = fieldDescribe.getLabel();
      Schema.DisplayType fieldType = fieldDescribe.getType();

      System.debug('Field Label: ' + fieldLabel);
      System.debug('Field Type: ' + fieldType);

      if (fieldValue != null) {
        keyValuePair.put(fieldName, fieldValue);
      }
    }
    System.debug('Fields with values: ' + keyValuePair);
  }
}
