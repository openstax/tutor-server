module OpenStax::Cnx::V1
  class Fragment::Exercise < Fragment

    # CSS to find the exercise embed code attribute
    EMBED_CODE_CSS = 'a[href^="#ost/api/ex/"]'

    # Regex to extract the appropriate tag from the embed code
    EMBED_TAG_REGEX = /\A#ost\/api\/ex\/([\w-]+)\z/

    # xpath to find the exercise embed code after url is absolutized
    ABSOLUTE_EMBED_CODE_XPATH = './/a[contains(@href, "/api/exercises")]'

    # Regex to extract the appropriate tag from absolutized url
    ABSOLUTE_EMBED_TAG_REGEX = /q=tag(?::|%3A)([\w-]+)$/

    def initialize(node:, title: nil, labels: [], short_code: nil)
      super(node: node, title: title, labels: labels)
      @short_code = short_code

      # Absolutized exercise url
      self.class.absolutize_url(@node)
    end

    def embed_code
      @embed_code ||= node.at_xpath(ABSOLUTE_EMBED_CODE_XPATH).try(:attribute, 'href').try(:value)
    end

    def embed_tag
      @short_code ||= ABSOLUTE_EMBED_TAG_REGEX.match(embed_code).try(:[], 1)
    end

    def exercise?
      true
    end

    def self.absolutize_exercise_urls(node)
      node.css(EMBED_CODE_CSS).each do |link|
        href = link.attribute('href')
        next if href.nil?

        exercises_url = OpenStax::Exercises::V1.configuration.server_url
        uri = Addressable::URI.join(exercises_url, '/api/exercises')

        short_code = EMBED_TAG_REGEX.match(href.value).try(:[], 1)
        uri.query_values = { q: "tag:#{short_code}" }
        href.value = uri.to_s
      end
    end

  end
end
