class Api::V1::Demo::Assign::TaskPlan::Representer < Roar::Decorator
  include Roar::JSON
  include Representable::Hash::AllowSymbols
  include Representable::Coercion

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

  property :num_core_exercises,
           type: Integer,
           readable: false,
           writeable: true

  property :exercises_count_dynamic,
           type: Integer,
           readable: false,
           writeable: true

  property :is_draft,
           type: Virtus::Attribute::Boolean,
           readable: false,
           writeable: true

  collection :book_locations,
             type: Array,
             readable: false,
             writeable: true,
             schema_info: { required: true }

  collection :assigned_to,
             extend: Api::V1::Demo::Assign::TaskPlan::AssignedTo::Representer,
             class: Hashie::Mash,
             readable: false,
             writeable: true,
             schema_info: { required: true }
end
