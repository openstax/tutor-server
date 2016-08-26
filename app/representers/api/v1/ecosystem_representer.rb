module Api::V1

  class EcosystemRepresenter < Roar::Decorator
    include Roar::JSON

    property :id,
             type: String,
             writeable: false,
             readable: true,
             schema_info: { required: true }

    property :comments,
             type: String,
             readable: true

    collection :books,
               readable: true,
               writable: false,
               extend: EcosystemBookRepresenter
  end


end
