class Api::V1::Research::StudentRepresenter < Roar::Decorator
  include Roar::JSON
  include Representable::Coercion

  property :id,
           type: String,
           readable: true,
           writeable: false,
           schema_info: { required: true }

  property :uuid,
           type: String,
           readable: true,
           writeable: false,
           schema_info: { required: true }

  property :entity_role_id,
           as: :role_id,
           type: String,
           readable: true,
           writeable: false,
           schema_info: { required: true }

  property :research_identifier,
           type: String,
           readable: true,
           writeable: false,
           schema_info: { required: true }

  property :is_active,
           readable: true,
           writeable: false,
           getter: ->(*) { !dropped? },
           schema_info: {
              required: true,
              type: 'boolean',
              description: "Student is dropped if false"
           }

  property :is_paid,
           readable: true,
           writeable: false,
           schema_info: {
              required: true,
              type: 'boolean',
              description: "True if student has paid"
           }

  property :is_comped,
           readable: true,
           writeable: false,
           schema_info: {
              required: true,
              type: 'boolean',
              description: "True if student has been comped"
           }
end
