module OpenStax::Cnx::V1::Fragment
  class Video

    # Used to get the title
    TITLE_CSS = '[data-type="title"]'

    # For fragments missing a proper title
    DEFAULT_TITLE = nil

    # CSS to find the video object
    VIDEO_OBJECT_CSS = '.os-embed'

    attr_reader :node

    def initialize(node:, title: nil)
      @node = node
      @title = title
    end

    def title
      return @title unless @title.nil?

      @title = node.css(TITLE_CSS).collect{|n| n.try(:content).try(:strip)}
                                  .compact.uniq.join('; ')
      @title = DEFAULT_TITLE if @title.blank?
      @title
    end

    def to_s(indent: 0)
      s = "#{' ' * indent}VIDEO #{title}\n"
    end

    def video(node = node)
      @video ||= node.at_css(VIDEO_OBJECT_CSS)
    end

    def video_type
      # Videos are in the form of a link like
      #   <a class="os-embed" href="...">video</a>
      #
      #   or embedded in an iframe like
      #   <div data-type="media"
      #        id="fs-id1172194359145"
      #        data-alt="alt text here"
      #        class="os-embed">
      #     <iframe width="560"
      #             height="315"
      #             src="https://www.youtube.com/embed/40ETbLVkLKc"/>
      #   </div>
      @video_type ||= case
                      when video.try(:name) == 'a'
                        :link
                      when video.try(:attr, :'data-type') == 'media'
                        :embedded
                      end
    end

    def to_html
      # Remove the video tag and replace it with just its text
      if @to_html.nil?
        node_copy = node.dup
        video_copy = video(node = node_copy)
        video_copy.replace(video_copy.text)
        @to_html = node_copy.to_html
      end
      @to_html
    end

    def url
      @url ||= case video_type
               when :link
                 video.attr(:href)
               when :embedded
                 video.try(:xpath, 'iframe/@src').to_s
      end
    end

  end
end
