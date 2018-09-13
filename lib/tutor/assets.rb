require_relative 'assets/manifest'

module Tutor
  module Assets

    def self.[](asset, ext)
      if @manifest.present?
        asset = @manifest["#{asset}.min.#{ext}"] # manifest assets are minimized
      else
        asset = "#{asset}.#{ext}"
      end
      "#{Rails.application.secrets.assets_url}/#{asset}"
    end

    # called by assets initializer as it boots
    def self.read_manifest
      @manifest = Manifest.pick_local_or_remote
      unless @manifest.present?
        Rails.logger.info "assets manifest is missing, running in development mode with assets served by webpack at #{Rails.application.secrets.assets_url}"
        @manifest = nil
      end
    end


    module Scripts
      def self.[](asset)
        Tutor::Assets["#{asset}", 'js']
      end
    end

  end
end
