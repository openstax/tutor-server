class Api::V1::CourseCloneRepresenter < Api::V1::CourseRepresenter

  property :catalog_offering_id,
           inherit: true,
           writeable: false

  property :copy_question_library,
           readable: false,
           writeable: true,
           schema_info: {
             required: true,
             type: 'boolean'
           }

end
