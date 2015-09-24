module Api::V1
  class PageRepresenter < Roar::Decorator

    include Roar::JSON

    property :content,
             as: :content_html,
             type: String,
             readable: true,
             writeabel: false

    property :ecosystem_title,
             type: String,
             readable: true,
             getter: ->(*) { ecosystem.title },
             writeable: false
  end
end
