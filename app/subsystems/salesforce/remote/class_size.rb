class Salesforce::Remote::ClassSize < ActiveForce::SObject

  field :using_concept_coach,       from: "Using_Concept_Coach__c", as: :boolean
  field :course_name,               from: "Course_Name__c"
  field :course_id,                 from: "Tutor_ID__c"
  field :created_at,                from: "Tutor_Created_Date__c", as: :datetime
  field :num_students,              from: "Student_using_Tutor__c", as: :int
  field :num_teachers,              from: "Active_Teachers__c"
  field :teacher_registration_url,  from: "Teacher_Registration_URL__c"
  field :error,                     from: "Tutor_Error__c"
  field :offering_uid,              from: "Book_Name__c"
  field :school,                    from: "School__c"

  self.table_name = 'Class_Size__c'

end
