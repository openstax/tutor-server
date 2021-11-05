class Api::V1::TaskPlan::Scores::QuestionHeadingRepresenter < Roar::Decorator
  include Roar::JSON
  include Representable::Coercion

  property :title,
           type: String,
           readable: true,
           writeable: false

  property :type,
           type: String,
           readable: true,
           writeable: false

  property :points_without_dropping,
           type: Float,
           readable: true,
           writeable: false

  property :points,
           type: Float,
           readable: true,
           writeable: false

  property :exercise_ids,
           type: Integer,
           readable: true,
           writeable: false

  property :question_ids,
           type: Integer,
           readable: true,
           writeable: false

  property :group_type,
           type: String,
           readable: true,
           writeable: false
end
