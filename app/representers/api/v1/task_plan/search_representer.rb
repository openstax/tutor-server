class Api::V1::TaskPlan::SearchRepresenter < OpenStax::Api::V1::AbstractSearchRepresenter
  collection :items, inherit: true,
                     class: ::Tasks::Models::TaskPlan,
                     extend: ::Api::V1::TaskPlan::Representer
end
