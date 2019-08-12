class Api::V1::Demo::Work::Representer < Api::V1::Demo::BaseRepresenter
  property :course,
           extend: Api::V1::Demo::Work::Course::Representer,
           class: Demo::Mash,
           readable: true,
           writeable: true,
           schema_info: { required: true }
end
