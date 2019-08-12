class Api::V1::Demo::Users::Representer < Api::V1::Demo::BaseRepresenter
  collection :administrators,
             extend: Api::V1::Demo::UserRepresenter,
             class: Demo::Mash,
             readable: true,
             writeable: true

  collection :content_analysts,
             extend: Api::V1::Demo::UserRepresenter,
             class: Demo::Mash,
             readable: true,
             writeable: true

  collection :customer_support,
             extend: Api::V1::Demo::UserRepresenter,
             class: Demo::Mash,
             readable: true,
             writeable: true

  collection :researchers,
             extend: Api::V1::Demo::UserRepresenter,
             class: Demo::Mash,
             readable: true,
             writeable: true

  collection :teachers,
             extend: Api::V1::Demo::UserRepresenter,
             class: Demo::Mash,
             readable: true,
             writeable: true

  collection :students,
             extend: Api::V1::Demo::UserRepresenter,
             class: Demo::Mash,
             readable: true,
             writeable: true
end
