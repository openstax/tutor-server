class Salesforce::Remote::Opportunity < ActiveForce::SObject

  field :term_year,                    from: "TermYear__c"
  field :book_name,                    from: "Book_Text__c"
  field :contact_id,                   from: "Contact__c"

  self.table_name = 'Opportunity'

  def term_year_object
    Salesforce::Remote::TermYear.from_string(self.term_year)
  end

end
