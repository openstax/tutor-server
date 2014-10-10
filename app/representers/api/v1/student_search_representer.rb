module Api::V1
  class StudentSearchRepresenter < OpenStax::Api::V1::AbstractSearchRepresenter

    property :total_count,
             inherit: true,
             schema_info: {
               description: "The number of students that match the query, can be more than the number returned"
             }

    collection :items,
               inherit: true,
               class: Student,
               decorator: Api::V1::StudentRepresenter,
               schema_info: {
                 description: "The students matching the query or a subset thereof when paginating"
               }

  end
end
