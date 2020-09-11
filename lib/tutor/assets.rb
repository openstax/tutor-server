require_relative 'assets/manifest'

module Tutor
  module Assets

    def self.tags(asset)
      if @manifest.nil?
        return "<script type='text/javascript' src='#{asset}' async></script>".html_safe
      end
      @manifest[asset].map do |chunk|
        "<script type='text/javascript' src='#{chunk['src']}'  async></script>"
      end.join("\n").html_safe
    end

    # called by assets initializer as it boots
    def self.read_manifest
      @manifest = Manifest.pick_local_or_remote
      unless @manifest.present?
        Rails.logger.info "assets manifest is missing, running in development mode with assets served by webpack at #{Rails.application.secrets.assets_url}"
        @manifest = nil
      end
    end

  end
end
