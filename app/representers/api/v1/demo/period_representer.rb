class Api::V1::Demo::PeriodRepresenter < Api::V1::Demo::BaseRepresenter
  property :name,
           type: String,
           readable: true,
           writeable: true,
           schema_info: { required: true }
end
