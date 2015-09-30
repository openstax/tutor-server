module Api::V1
  class ClueRepresenter < Roar::Decorator
    include Roar::JSON
    include Representable::Coercion

    property :value,
             type: Float,
             readable: true,
             writeable: false,
             schema_info: {
               required: true,
               description: "The raw CLUE value, a number between 0.0 and 1.0, inclusive."
             }

    property :value_interpretation,
             type: String,
             readable: true,
             writeable: false,
             schema_info: {
               required: true,
               description: "A binning of the value into 'low', 'medium', and 'high' groups"
             }

    property :confidence_interval,
             type: Array,
             readable: true,
             writeable: false,
             schema_info: {
               required: true,
               description: 'The lower and upper bounds of the confidence interval, expressed as an array e.g. [0.3, 0.5]'
             }

    property :confidence_interval_interpretation,
             type: String,
             readable: true,
             writeable: false,
             schema_info: {
               required: true,
               description: "Describes the confidence interval as either 'good' or 'bad'"
             }

    property :sample_size,
             type: Integer,
             readable: true,
             writeable: false,
             schema_info: {
               required: true,
               description: "The total number of data points considered"
             }

    property :sample_size_interpretation,
             type: String,
             readable: true,
             writeable: false,
             schema_info: {
               required: true,
               description: "Returns 'above' or 'below' depending on if the sample size is above or below an internal threshold"
             }

    property :unique_learner_count,
             type: Integer,
             readable: true,
             writeable: false,
             schema_info: {
               required: true,
               description: "The number of learners that contributed to the data points considered"
             }

  end
end
