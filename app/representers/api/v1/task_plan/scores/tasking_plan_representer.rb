class Api::V1::TaskPlan::Scores::TaskingPlanRepresenter < Api::V1::TaskPlan::TaskingPlanRepresenter
  property :period_id,
           type: String,
           readable: true,
           writeable: false

  property :period_name,
           type: String,
           readable: true,
           writeable: false

  collection :question_headings,
             readable: true,
             writeable: false,
             extend: Api::V1::TaskPlan::Scores::QuestionHeadingRepresenter

  property :late_work_fraction_penalty,
           type: Float,
           readable: true,
           writeable: false

  property :num_questions_dropped,
           type: Integer,
           readable: true,
           writeable: false

  property :points_dropped,
           type: Float,
           readable: true,
           writeable: false

  collection :students,
             readable: true,
             writeable: false,
             extend: Api::V1::TaskPlan::Scores::StudentRepresenter

  property :questions_need_grading,
           readable: true,
           writeable: false,
           schema_info: { type: 'boolean' }

  property :grades_need_publishing,
           readable: true,
           writeable: false,
           schema_info: { type: 'boolean' }
end
