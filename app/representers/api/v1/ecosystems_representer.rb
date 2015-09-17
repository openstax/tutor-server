module Api::V1

  class EcosystemsRepresenter < Roar::Decorator

    include Representable::JSON::Collection

    items extend: Api::V1::EcosystemRepresenter

  end
end
