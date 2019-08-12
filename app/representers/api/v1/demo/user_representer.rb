class Api::V1::Demo::UserRepresenter < Api::V1::Demo::BaseRepresenter
  property :username,
           type: String,
           readable: true,
           writeable: true,
           schema_info: { required: true }

  property :full_name,
           type: String,
           readable: true,
           writeable: true

  property :first_name,
           type: String,
           readable: true,
           writeable: true

  property :last_name,
           type: String,
           readable: true,
           writeable: true

  property :is_test,
           type: Virtus::Attribute::Boolean,
           readable: true,
           writeable: true
end
