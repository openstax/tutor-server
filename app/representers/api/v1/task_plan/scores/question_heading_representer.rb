class Api::V1::TaskPlan::Scores::QuestionHeadingRepresenter < Roar::Decorator
  include Roar::JSON

  property :index,
           type: Integer,
           readable: true,
           writeable: false

  property :title,
           type: String,
           readable: true,
           writeable: false

  property :type,
           type: String,
           readable: true,
           writeable: false
end
