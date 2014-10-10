module Api::V1
  class StudentRepresenter < Roar::Decorator

    include Roar::Representer::JSON

    property :user,
             class: User,
             decorator: UserRepresenter,
             readable: true,
             writeable: false,
             schema_info: {
               description: "The associated user"
             }

    property :klass_id,
             as: :class_id,
             type: Integer,
             readable: true,
             writeable: false,
             schema_info: {
               description: "The associated class's ID"
             }

    property :section_id,
             type: Integer,
             readable: true,
             writeable: true,
             schema_info: {
               description: "The ID of the section the student is in"
             }

    property :level,
             type: Integer,
             readable: true,
             writeable: true,
             schema_info: {
               description: "The student's status within the class"
             }

    property :has_dropped,
             readable: true,
             writeable: true,
             schema_info: {
               type: 'boolean',
               description: "Whether the stuent has dropped the class"
             }

    property :student_custom_identifier,
             type: String,
             readable: true,
             writeable: true,
             schema_info: {
               description: "A custom identifier set by the student"
             }

    property :educator_custom_identifier,
             type: String,
             readable: true,
             writeable: true,
             schema_info: {
               description: "A custom identifier set by the educator"
             }

    property :random_education_identifier,
             type: String,
             readable: true,
             writeable: false,
             schema_info: {
               description: "A fully randomized identifier"
             }

  end
end
