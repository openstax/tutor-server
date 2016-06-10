module OpenStax::Cnx::V1
  class Fragment::Exercise < Fragment

    # CSS to find the exercise embed code attribute(s)
    EMBED_CODE_CSS = 'a[href^="#ost/api/ex/"]'

    # Regex to extract the appropriate tag from the embed code(s)
    EMBED_TAG_REGEX = /\A#ost\/api\/ex\/([\w-]+)\z/

    # XPath to find the exercise embed code(s) after the url(s) are absolutized
    ABSOLUTE_EMBED_CODE_XPATH = './/a[contains(@href, "/api/exercises")]'

    # Regex to extract the appropriate embed tag(s) from the absolutized url(s)
    ABSOLUTE_EMBED_TAG_REGEX = /\/api\/exercises\/?\?q=tag(?::|%3A)(?:"|%22)?([\w-]+)(?:"|%22)?\z/

    attr_reader :embed_tags

    def self.absolutize_exercise_urls(node)
      node.css(EMBED_CODE_CSS).each do |anchor|
        href = anchor.attribute('href')
        embed_tag = EMBED_TAG_REGEX.match(href.value).try(:[], 1)
        uri = OpenStax::Exercises::V1.uri_for('/api/exercises')
        uri.query_values = { q: "tag:\"#{embed_tag}\"" }
        href.value = uri.to_s
      end
    end

    def initialize(node:, title: nil, labels: [])
      # Absolutized exercise url(s)
      self.class.absolutize_exercise_urls(node)

      super

      embed_codes = node.xpath(ABSOLUTE_EMBED_CODE_XPATH).map do |anchor|
        anchor.attribute('href').value
      end
      @embed_tags = embed_codes.map do |embed_code|
        ABSOLUTE_EMBED_TAG_REGEX.match(embed_code).try(:[], 1)
      end.compact
    end

    def blank?
      embed_tags.empty? && node_id.blank?
    end

  end
end
