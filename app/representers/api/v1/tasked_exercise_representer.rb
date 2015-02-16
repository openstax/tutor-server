module Api::V1
  class TaskedExerciseRepresenter < Api::V1::TaskStepRepresenter

    property :correct_answer_id,
             type: Integer,
             if: lambda {|*| false}

    property :answer_id,
             type: Integer,
             if: lambda {|*| false}

    property :free_response,
             type: String,
             if: lambda {|*| false}

    property :feedback_html
             type: String,
             if: lambda {|*| false}

    property :content,
             type: String,
             writeable: false,
             readable: true,
             schema_info: {
               required: false,
               description: "The Resource content as HTML"
             }
  end
end
