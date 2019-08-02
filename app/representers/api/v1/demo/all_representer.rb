class Api::V1::Demo::AllRepresenter < Api::V1::Demo::BaseRepresenter
  property :users,
           extend: Api::V1::Demo::Users::Representer,
           class: Demo::Mash,
           readable: true,
           writeable: true,
           schema_info: { required: true }

  property :import,
           extend: Api::V1::Demo::Import::Representer,
           class: Demo::Mash,
           readable: true,
           writeable: true,
           schema_info: { required: true }

  property :course,
           extend: Api::V1::Demo::Course::Representer,
           class: Demo::Mash,
           readable: true,
           writeable: true,
           schema_info: { required: true }

  property :assign,
           extend: Api::V1::Demo::Assign::Representer,
           class: Demo::Mash,
           readable: true,
           writeable: true,
           schema_info: { required: true }

  property :work,
           extend: Api::V1::Demo::Work::Representer,
           class: Demo::Mash,
           readable: true,
           writeable: true,
           schema_info: { required: true }
end
