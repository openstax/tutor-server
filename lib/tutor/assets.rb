module Tutor
  module Assets

    def self.[](asset, ext)
      if @manifest.present? # if it's in manifest it's minimized
        asset = @manifest["#{asset}.min.#{ext}"]
      else
        asset = "#{asset}.#{ext}"
      end
      "#{Rails.application.secrets.assets_url}/#{asset}"
    end

    # called by assets initializer as it boots
    def self.read_manifest
      begin
        @manifest = JSON.parse Rails.root.join('public', 'assets', 'rev-manifest.json').read
        @manifest.default_proc = proc do |_, asset|
          raise("Asset #{asset} does not exist")
        end
      rescue Errno::ENOENT
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
