class Api::V1::Demo::Users::Representer < Roar::Decorator
  include Roar::JSON
  include Representable::Hash::AllowSymbols
  include Representable::Coercion

  collection :administrators,
             extend: Api::V1::Demo::UserRepresenter,
             class: Hashie::Mash,
             readable: true,
             writeable: true

  collection :content_analysts,
             extend: Api::V1::Demo::UserRepresenter,
             class: Hashie::Mash,
             readable: true,
             writeable: true

  collection :customer_support,
             extend: Api::V1::Demo::UserRepresenter,
             class: Hashie::Mash,
             readable: true,
             writeable: true

  collection :researchers,
             extend: Api::V1::Demo::UserRepresenter,
             class: Hashie::Mash,
             readable: true,
             writeable: true

  collection :teachers,
             extend: Api::V1::Demo::UserRepresenter,
             class: Hashie::Mash,
             readable: true,
             writeable: true

  collection :students,
             extend: Api::V1::Demo::UserRepresenter,
             class: Hashie::Mash,
             readable: true,
             writeable: true
end
