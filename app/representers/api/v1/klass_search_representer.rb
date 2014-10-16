module Api::V1
  class KlassSearchRepresenter < OpenStax::Api::V1::AbstractSearchRepresenter

    property :total_count,
             inherit: true,
             schema_info: {
               description: "The number of classes that match the query, can be more than the number returned"
             }

    collection :items,
               inherit: true,
               class: Klass,
               decorator: Api::V1::KlassRepresenter,
               schema_info: {
                 description: "The classes matching the query or a subset thereof when paginating"
               }

  end
end
