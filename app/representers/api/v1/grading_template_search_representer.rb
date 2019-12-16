class Api::V1::GradingTemplateSearchRepresenter < OpenStax::Api::V1::AbstractSearchRepresenter
  collection :items, inherit: true, extend: Api::V1::GradingTemplateRepresenter
end
