module OpenStax::Cnx::V1::Fragment
  class Video < Text

    # CSS to find the video link
    VIDEO_LINK_CSS = '.os-embed'

    def url
      video = node.at_css(VIDEO_LINK_CSS)
      @url ||= case
      when video.try(:name) == 'a'
        video.attr(:href)
      when video.try(:attr, :'data-type') == 'media'
        video.try(:xpath, 'iframe/@src')
      end
    end

  end
end
