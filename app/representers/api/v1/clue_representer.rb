module Api::V1
  class ClueRepresenter < Roar::Decorator
    include Roar::JSON
    include Representable::Coercion

    property :minimum,
             type: Float,
             readable: true,
             writeable: false,
             schema_info: {
               required: true,
               description: "The lower bound of the CLUe's confidence interval"
             }

    property :most_likely,
             type: Float,
             readable: true,
             writeable: false,
             schema_info: {
               required: true,
               description: "The most likely CLUe value"
             }

    property :maximum,
             type: Float,
             readable: true,
             writeable: false,
             schema_info: {
               required: true,
               description: "The upper bound of the CLUe's confidence interval"
             }

    property :is_real,
             readable: true,
             writeable: false,
             schema_info: {
               type: 'boolean',
               required: true,
               description: "Whether or not we had enough responses to actually compute the CLUe"
             }

    property :ecosystem_uuid,
             type: String,
             readable: true,
             writeable: false,
             schema_info: {
               description: "The UUID of the Ecosystem used to compute this CLUe"
             }
  end
end
