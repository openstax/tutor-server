class Api::V1::Demo::Assign::TaskPlan::Representer < Roar::Decorator
  include Roar::JSON
  include Representable::Hash::AllowSymbols
  include Representable::Coercion

  # One of either id or title is required
  property :id,
           type: String,
           readable: true,
           writeable: true

  property :title,
           type: String,
           readable: true,
           writeable: true

  property :type,
           type: String,
           readable: true,
           writeable: true,
           schema_info: { required: true }

  property :exercises_count_core,
           type: Integer,
           readable: false,
           writeable: true

  property :exercises_count_dynamic,
           type: Integer,
           readable: false,
           writeable: true

  property :is_published,
           type: Virtus::Attribute::Boolean,
           readable: false,
           writeable: true,
           getter: ->(*) { respond_to?(:is_published) ? is_published : is_published? }

  collection :book_locations,
             extend: Api::V1::Demo::Assign::TaskPlan::BookLocationRepresenter,
             class: Demo::Mash,
             readable: false,
             writeable: true,
             schema_info: { required: true }

  collection :assigned_to,
             extend: Api::V1::Demo::Assign::TaskPlan::AssignedTo::Representer,
             class: Demo::Mash,
             readable: false,
             writeable: true,
             schema_info: { required: true }
end
