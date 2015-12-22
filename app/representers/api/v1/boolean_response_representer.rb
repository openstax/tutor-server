module Api::V1

  # Representer for replying with a simple true/false message
  class BooleanResponseRepresenter < Roar::Decorator

    include Roar::JSON

    property :response,
             type: 'boolean',
             readable: true,
             writeable: false,
             schema_info: { required: true }

  end
end
