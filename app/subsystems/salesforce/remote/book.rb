class Salesforce::Remote::Book < ActiveForce::SObject

  field :name,                      from: "Name"

  self.table_name = 'Book__c'

end
