module Api::V1

  class EcosystemRepresenter < Roar::Decorator
    include Roar::JSON

    property :id,
             type: String,
             writeable: false,
             readable: true,
             schema_info: { required: true }

    collection :books,
               readable: true,
               writable: false,
               decorator: EcosystemBookRepresenter
  end


end
