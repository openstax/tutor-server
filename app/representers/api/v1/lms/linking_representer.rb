module Api::V1::Lms

  class LinkingRepresenter < Roar::Decorator

    include Roar::JSON

    property :key,
             type: String,
             writeable: false,
             readable: true

    property :secret,
             type: String,
             writeable: false,
             readable: true

    property :configuration_url,
             type: String,
             writeable: false,
             readable: true,
             getter: ->(*) { UrlGenerator.new.lms_configuration_url(format: :xml) }

    property :launch_url,
             type: String,
             writeable: false,
             readable: true,
             getter: ->(*) { UrlGenerator.new.lms_launch_url }

    property :xml,
             type: String,
             writeable: false,
             readable: true,
             getter: ->(user_options:, **) { user_options[:xml] }
  end

end
