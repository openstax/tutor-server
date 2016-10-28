class Api::V1::CourseCloneRepresenter < Api::V1::CourseRepresenter

  property :copy_question_library,
           readable: false,
           writeable: true,
           schema_info: {
             required: true,
             type: 'boolean'
           }

end
