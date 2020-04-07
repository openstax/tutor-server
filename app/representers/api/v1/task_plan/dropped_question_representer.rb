class Api::V1::TaskPlan::DroppedQuestionRepresenter < Roar::Decorator
  include Roar::JSON
  include Representable::Coercion

  property :question_id,
           type: String,
           readable: true,
           writeable: true,
           schema_info: { required: true }

  property :drop_method,
           type: String,
           readable: true,
           writeable: true,
           schema_info: { required: true }
end
