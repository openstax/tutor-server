class Api::V1::GradingTemplateRepresenter < Roar::Decorator
  include Roar::JSON
  include Representable::Coercion

  property :id,
           type: String,
           readable: true,
           writeable: false,
           schema_info: { required: true }

  property :course_profile_course_id,
           as: :course_id,
           type: String,
           readable: true,
           writeable: false,
           schema_info: { required: true }

  property :cloned_from_id,
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

  property :deleted_at,
           type: String,
           readable: true,
           writeable: false,
           getter: ->(*) { DateTimeUtilities.to_api_s( deleted_at ) }

  property :correctness_weight,
           type: Float,
           readable: true,
           writeable: true,
           schema_info: { required: true }

  property :auto_grading_feedback_on,
           type: String,
           writeable: true,
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
           writeable: true,
           readable: true,
           schema_info: {
             required: true,
             type: 'enum',
             description: <<~DESCRIPTION
               When feedback should be shown to students for manually graded questions.
               One of either "grade" or "publish"
             DESCRIPTION
           }

  property :late_work_penalty_applied,
           type: String,
           readable: true,
           writeable: true,
           schema_info: { required: true }

  property :late_work_penalty,
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

  property :created_at,
           type: String,
           readable: true,
           writeable: false,
           getter: ->(*) { DateTimeUtilities.to_api_s(created_at) },
           schema_info: { required: true }

  property :has_open_task_plans?,
           as: :has_open_task_plans,
           readable: true,
           writeable: false,
           schema_info: {
             required: true,
             type: 'boolean'
           }
end
