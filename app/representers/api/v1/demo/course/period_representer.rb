class Api::V1::Demo::Course::PeriodRepresenter < Api::V1::Demo::PeriodRepresenter
  property :enrollment_code,
           type: String,
           readable: true,
           writeable: true

  collection :students,
             extend: Api::V1::Demo::UserRepresenter,
             class: Demo::Mash,
             readable: true,
             writeable: true,
             schema_info: { required: true }
end
