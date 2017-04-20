class Salesforce::Remote::IndividualAdoption < ActiveForce::SObject

  field :book_name,                    from: "Book_Text__c"
  field :contact_id,                   from: "Contact__c"
  field :book_id,                      from: "Book__c"
  field :school_id,                    from: "Account__c"
  field :school_year,                  from: "School_Year__c"
  field :fall_start_date,              from: "Fall_Start_Date__c"
  field :summer_start_date,            from: "Summer_Start_Date__c"
  field :winter_start_date,            from: "Winter_Start_Date__c"
  field :spring_start_date,            from: "Spring_Start_Date__c"
  field :adoption_level,               from: "Adoption_Level__c"
  field :description,                  from: "Description__c"

  # Deprecated
  field :term_year,                    from: "TermYear__c"
  field :class_start_date,             from: "Class_Start_Date__c"

  belongs_to :school, model: Salesforce::Remote::School
  belongs_to :book, model: Salesforce::Remote::Book

  self.table_name = 'Individual_Adoption__c'

  def term_year_object
    @term_year_object ||= Salesforce::Remote::TermYear.from_string(term_year)
  end

end
