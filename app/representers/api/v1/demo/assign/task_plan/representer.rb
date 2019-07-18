class Api::V1::Demo::Assign::TaskPlan::Representer < Roar::Decorator
  include Roar::JSON

  property :title,
           type: String,
           readable: true,
           writeable: true,
           schema_info: { required: true }

  property :type,
           type: String,
           readable: true,
           writeable: true,
           schema_info: { required: true }

  property :num_exercises,
           type: Integer,
           readable: true,
           writeable: true

  collection :book_locations,
             extend: Api::V1::Demo::Assign::TaskPlan::BookLocationRepresenter,
             readable: true,
             writeable: true,
             schema_info: { required: true }

  collection :assigned_to,
             extend: Api::V1::Demo::Assign::TaskPlan::AssignedTo::Representer,
             readable: true,
             writeable: true,
             schema_info: { required: true }
end
