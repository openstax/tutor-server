class OpenStax::Cnx::V1::Fragment
  class Video < Embedded

    self.default_width = 560
    self.default_height = 315

    # This code is run from lib/openstax/cnx/v1/page.rb during import
    def self.replace_video_links_with_iframes(node)
      # Currently there is no tagging legend markup for video links
      # that have to be converted to iframes
      node
    end

  end
end
