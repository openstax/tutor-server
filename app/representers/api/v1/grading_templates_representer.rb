class Api::V1::GradingTemplatesRepresenter < Roar::Decorator
  include Representable::JSON::Collection

  items extend: Api::V1::GradingTemplateRepresenter
end
