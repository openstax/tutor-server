require_relative 'assets/manifest'

module Tutor
  module Assets
    # TODO: Re-read manifest (on every request?) so we can deploy FE without restarting BE
    mattr_accessor :manifest

    def self.url
      url = Rails.application.secrets.assets_url
      url.ends_with?('/') ? url : "#{url}/"
    end

    def self.url_for(asset)
      "#{url}#{asset}"
    end

    def self.tags(asset)
      if manifest.nil? || manifest[asset].nil?
        return "<script type='text/javascript' src='#{url_for(asset)}.js' async></script>".html_safe
      end

      manifest[asset].map do |chunk|
        "<script type='text/javascript' src='#{chunk['src']}' crossorigin='anonymous' async></script>"
      end.join("\n").html_safe
    end

    def self.unique_key(asset)
      Digest::MD5.hexdigest tags(asset)
    end

    # called by assets initializer as it boots
    def self.read_manifest
      self.manifest = Tutor::Assets::Manifest::ManifestParser.new

      unless manifest.present?
        Rails.logger.info "assets manifest is missing, running in development mode with assets served by webpack at #{url}"
        self.manifest = nil
      end
    end
  end
end
