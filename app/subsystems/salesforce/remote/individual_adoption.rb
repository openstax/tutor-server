class Salesforce::Remote::IndividualAdoption < ActiveForce::SObject

  field :term_year,                    from: "TermYear__c"
  field :book_name,                    from: "Book_Text__c"
  field :contact_id,                   from: "Contact__c"
  field :class_start_date,             from: "Class_Start_Date__c"
  field :book_id,                      from: "Book__c"
  field :school_id,                    from: "Account__c"

  belongs_to :school, model: Salesforce::Remote::School
  belongs_to :book, model: Salesforce::Remote::Book

  self.table_name = 'Individual_Adoption__c'

  def term_year_object
    @term_year_object ||= Salesforce::Remote::TermYear.from_string(term_year)
  end

end
