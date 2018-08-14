module Tutor
  module Assets

    def self.[](asset)
      if @manifest.nil?
        "#{Rails.application.secrets.assets_url}/dist/#{asset}"
      else
        @manifest["/assets/#{asset}.min"]
      end
    end

    # called by assets initializer as it boots
    def self.read_manifiest
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
        Tutor::Assets[asset] + '.js'
      end
    end

  end
end
