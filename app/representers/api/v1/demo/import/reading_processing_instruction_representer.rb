class Api::V1::Demo::Import::ReadingProcessingInstructionRepresenter < Roar::Decorator
  include Representable::JSON::Hash
  include Representable::Hash::AllowSymbols
  include Representable::Coercion

  property :css,
           type: String,
           readable: true,
           writeable: true,
           schema_info: { required: true }

  collection :fragments,
             type: String,
             readable: true,
             writeable: true,
             schema_info: { required: true }

  collection :labels,
             type: String,
             readable: true,
             writeable: true

  collection :only,
             type: String,
             readable: true,
             writeable: true

  collection :except,
             type: String,
             readable: true,
             writeable: true
end
