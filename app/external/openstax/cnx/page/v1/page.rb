module OpenStax::Cnx::V1
  class Page
    def initialize(id:, title:, fragments:, los: [])
      @id        = id
      @title     = title
      @fragments = fragments
      @los       = los
    end

    def to_s(indent: 0)
      s = "#{' '*indent}PAGE #{@title} // #{@id}\n"
    end

    def self.from_contents_hash(hash)
      page_hash = OpenStax::Cnx::V1.fetch(hash['id'])
      content = page_hash.fetch('content') { raise "ill-formed Page (id=#{id})" }
      fragments = [] ## DANTE TODO: extract_content_fragments(content)
      Page.new(id: hash['id'], title: hash['title'], fragments: fragments)
    end
  end
end
