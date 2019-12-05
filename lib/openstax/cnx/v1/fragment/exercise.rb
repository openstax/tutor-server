module OpenStax::Cnx::V1
  class Fragment::Exercise < Fragment
    # CSS to find the embed code attributes
    EXERCISE_EMBED_URL_CSS = 'a[href^="#"]'

    # Regex to extract the appropriate tag from the embed code(s)
    EXERCISE_EMBED_URL_REGEXES = {
      tag: /\A#ost\/api\/ex\/([\w\s-]+)\z/,
      nickname: /\A#exercises?\/([\w\s-]+)\z/
    }

    # CSS to find the exercise embed queries after the urls are absolutized
    ABSOLUTIZED_EMBED_URL_CSS = 'a[href*="/api/exercises"]'

    # Regex to extract the appropriate embed queries from the absolutized urls
    ABSOLUTIZED_EMBED_URL_REGEX = \
      /\/api\/exercises\/?\?q=(tag|nickname)(?::|%3A)(?:"|%22)?([\w\s%-]+?)(?:"|%22)?\z/

    attr_reader :embed_queries

    # This code is run from lib/openstax/cnx/v1/page.rb during import
    def self.absolutize_exercise_urls!(node)
      uri = OpenStax::Exercises::V1.uri_for('/api/exercises')

      node.css(EXERCISE_EMBED_URL_CSS).each do |anchor|
        href = anchor.attribute('href')

        EXERCISE_EMBED_URL_REGEXES.each do |field, regex|
          embed_match = regex.match(href.value)
          next if embed_match.nil?

          uri.query_values = { q: "#{field}:\"#{embed_match[1]}\"" }
          href.value = uri.to_s
          anchor['data-type'] = 'exercise'
          break
        end
      end
    end

    def initialize(node:, title: nil, labels: [])
      super

      @embed_queries = node.css(ABSOLUTIZED_EMBED_URL_CSS).map do |anchor|
        url = anchor.attribute('href').value
        match = ABSOLUTIZED_EMBED_URL_REGEX.match(url)
        next if match.nil?

        [ match[1].to_sym, URI.unescape(match[2]) ]
      end.compact
    end

    def blank?
      embed_queries.empty? && node_id.blank?
    end
  end
end
