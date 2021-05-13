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

  # TODO: Remove 1 release after the above 2 fields get added
  property :exercise_id,
           type: Integer,
           readable: true,
           writeable: false

  property :question_id,
           type: Integer,
           readable: true,
           writeable: false
end
