class Api::V1::TaskPlan::Scores::StudentQuestionRepresenter < Roar::Decorator
  include Roar::JSON
  include Representable::Coercion

  property :task_step_id,
           type: String,
           readable: true,
           writeable: false

  property :exercise_id,
           type: String,
           readable: true,
           writeable: false

  property :question_id,
           type: String,
           readable: true,
           writeable: false

  property :points,
           type: Float,
           readable: true,
           writeable: false

  property :is_completed,
           schema_info: { required: true, type: 'boolean' },
           readable: true,
           writeable: false

  property :selected_answer_id,
           type: String,
           readable: true,
           writeable: false

  property :free_response,
           type: String,
           readable: true,
           writeable: false

  property :grader_points,
           type: Float,
           readable: true,
           writeable: false

  property :grader_comments,
           type: String,
           readable: true,
           writeable: false

  property :needs_grading,
           readable: true,
           writeable: false,
           schema_info: { type: 'boolean' }
end
