class Salesforce::Remote::ClassSize < ActiveForce::SObject

  field :concept_coach_approved,    from: "Concept_Coach_Approved__c", as: :boolean
  field :course_name,               from: "Course_Name__c"
  field :course_id,                 from: "Tutor_ID__c"
  field :created_at,                from: "Tutor_Created_Date__c", as: :datetime
  field :num_students,              from: "Student_using_Tutor__c", as: :int
  field :num_teachers,              from: "Active_Teachers__c", as: :int
  field :num_sections,              from: "Number_of_Sections__c", as: :int
  field :teacher_join_url,          from: "Teacher_Join_URL__c"
  field :error,                     from: "Tutor_Error__c"
  field :book_name,                 from: "Book_Name__c"
  field :school,                    from: "School__c"
  field :term_year,                 from: "TermYear__c"
  field :opportunity_id,            from: 'Opportunity__c'

  belongs_to :opportunity, model: Salesforce::Remote::Opportunity

  self.table_name = 'Class_Size__c'

  def term_year_object
    Salesforce::Remote::TermYear.from_string(self.term_year)
  end

  def reset_stats
    self.num_students = 0
    self.num_teachers = 0
    self.num_sections = 0
  end

  # Methods to make this legacy SF object compatible with current OsAncillary interface.
  # All ClassSize records were used for college CC courses.

  def is_tutor?
    false
  end

  def is_concept_coach?
    true
  end

  def valid_product?
    true
  end

  def is_college?
    true
  end

  def product
    "Concept Coach"
  end

end
