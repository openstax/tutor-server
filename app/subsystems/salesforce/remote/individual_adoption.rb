class Salesforce::Remote::IndividualAdoption < ActiveForce::SObject

  field :term_year,                    from: "TermYear__c"
  field :book_name,                    from: "Book_Text__c"
  field :contact_id,                   from: "Contact__c"

  self.table_name = 'Individual_Adoption__c'

  def term_year_object
    @term_year_object ||= Salesforce::Remote::TermYear.from_string(term_year)
  end

end
