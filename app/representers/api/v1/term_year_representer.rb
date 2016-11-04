class Api::V1::TermYearRepresenter < Roar::Decorator

  include Roar::JSON

  property :term,
           type: String,
           readable: true,
           writeable: false,
           schema_info: { required: true }

  property :year,
           type: Integer,
           readable: true,
           writeable: false,
           schema_info: { required: true }

end
