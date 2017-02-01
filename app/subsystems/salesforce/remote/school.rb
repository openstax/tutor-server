class Salesforce::Remote::School < ActiveForce::SObject

  field :name,                      from: "Name"

  self.table_name = 'Account'

end
