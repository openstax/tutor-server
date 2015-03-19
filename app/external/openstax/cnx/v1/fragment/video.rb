module OpenStax::Cnx::V1::Fragment
  class Video < Text

    # CSS to find the video link
    VIDEO_LINK_CSS = '.os-embed'

    def url
      @url ||= node.at_css(VIDEO_LINK_CSS).try(:attr, :href)
    end

  end
end
