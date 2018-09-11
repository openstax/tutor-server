module Tutor
  module Assets

    class Manifest

      SOURCE = Rails.root.join('public', 'assets', 'rev-manifest.json')

      def [](asset)
        read if SOURCE.mtime != @mtime
        @contents[asset]
      end

      def read
        @contents = JSON.parse(SOURCE.read)
        @contents.default_proc = proc do |_, asset|
          raise("Asset #{asset} does not exist")
        end
        @mtime = SOURCE.mtime
        Rails.logger.info "read assets manifest at #{SOURCE.expand_path}"
      end

      def present?
        SOURCE.exist?
      end
    end

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
      @manifest = Manifest.new
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
