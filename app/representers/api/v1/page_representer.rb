module Api::V1
  class PageRepresenter < Roar::Decorator

    include Roar::JSON

    property :content,
             as: :content_html,
             type: String,
             readable: true,
             writeabel: false

    property :spy,
             type: Object,
             readable: true,
             getter: ->(*) { {ecosystem_title: ecosystem.title} },
             writeable: false
  end
end
