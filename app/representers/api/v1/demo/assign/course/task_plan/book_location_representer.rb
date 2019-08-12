class Api::V1::Demo::Assign::Course::TaskPlan::BookLocationRepresenter < Api::V1::Demo::BaseRepresenter
  property :chapter,
           type: Integer,
           readable: true,
           writeable: true,
           schema_info: { required: true }

  property :section,
           type: Integer,
           readable: true,
           writeable: true,
           schema_info: { required: true }
end
