class Api::V1::GradingTemplateRepresenter < Roar::Decorator
  include Roar::JSON
  include Representable::Coercion

  property :id,
           type: String,
           readable: true,
           writeable: false,
           schema_info: { required: true }

  property :task_plan_type,
           type: String,
           readable: true,
           writeable: true,
           schema_info: { required: true }

  property :name,
           type: String,
           readable: true,
           writeable: true,
           schema_info: { required: true }

  property :completion_weight,
           type: Float,
           readable: true,
           writeable: true,
           schema_info: { required: true }

  property :correctness_weight,
           type: Float,
           readable: true,
           writeable: true,
           schema_info: { required: true }

    property :auto_grading_feedback_on,
             type: String,
             writeable: false,
             readable: true,
             schema_info: {
               required: true,
               type: 'enum',
               description: <<~DESCRIPTION
                 When feedback should be shown to students for automatically graded questions.
                 One of either "answer", "due" or "publish"
               DESCRIPTION
             }

    property :manual_grading_feedback_on,
             type: String,
             writeable: false,
             readable: true,
             schema_info: {
               required: true,
               type: 'enum',
               description: <<~DESCRIPTION
                 When feedback should be shown to students for manually graded questions.
                 One of either "grade" or "publish"
               DESCRIPTION
             }

  property :late_work_immediate_penalty,
           type: Float,
           readable: true,
           writeable: true,
           schema_info: { required: true }

  property :late_work_per_day_penalty,
           type: Float,
           readable: true,
           writeable: true,
           schema_info: { required: true }

  property :default_open_time,
           type: String,
           readable: true,
           writeable: true,
           schema_info: { required: true }

  property :default_due_time,
           type: String,
           readable: true,
           writeable: true,
           schema_info: { required: true }

  property :default_due_date_offset_days,
           type: Integer,
           readable: true,
           writeable: true,
           schema_info: { required: true }

  property :default_close_date_offset_days,
           type: Integer,
           readable: true,
           writeable: true,
           schema_info: { required: true }
end
