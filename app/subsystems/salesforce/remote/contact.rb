class Salesforce::Remote::Contact < ActiveForce::SObject
  belongs_to :school, foreign_key: :school_id,
                      model: Salesforce::Remote::School

  field :name,                    from: "Name"
  field :first_name,              from: "FirstName"
  field :last_name,               from: "LastName"
  field :email,                   from: "Email"
  field :email_alt,               from: "Email_alt__c"
  field :faculty_confirmed_date,  from: "Faculty_Confirmed_Date__c", as: :datetime
  field :faculty_verified,        from: "Faculty_Verified__c"
  field :last_modified_at,        from: "LastModifiedDate"
  field :school_id,               from: "AccountId"

  self.table_name = 'Contact'
end
