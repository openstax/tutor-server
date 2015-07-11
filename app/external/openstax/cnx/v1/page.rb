module OpenStax::Cnx::V1
  class Page

    include FragmentSplitter

    # Start parsing here
    ROOT_CSS = 'html > body'

    # Remove completely
    DISCARD_CSS = '.ost-reading-discard, .os-teacher, [data-type="glossary"]'

    # Find nodes that define relevant tags
    LO_DEF_NODE_CSS = '.ost-learning-objective-def'
    STD_DEF_NODE_CSS = '.ost-standards-def'
    TEKS_DEF_NODE_CSS = '.ost-standards-teks'
    APBIO_DEF_NODE_CSS = '.ost-standards-apbio'

    STD_NAME_NODE_CSS = '.ost-standards-name'
    STD_DESC_NODE_CSS = '.ost-standards-description'

    # Find specific tags and extract the relevant parts
    LO_REGEX = /ost-tag-lo-([\w+-]+)/
    STD_REGEX = /ost-tag-std-([\w+-]+)/
    TEKS_REGEX = /ost-tag-(teks-[\w+-]+)/
    APLO_REGEX = /ost-tag-std-apbio-lo-([\w+-]+)/

    def initialize(hash: {}, chapter_section: [], is_intro: nil, id: nil, url: nil,
                   title: nil, full_hash: nil, content: nil, los: nil, fragments: nil, tags: nil)
      @hash            = hash
      @chapter_section = chapter_section
      @is_intro        = is_intro
      @id              = id
      @url             = url
      @title           = title
      @full_hash       = full_hash
      @content         = content
      @los             = los
      @fragments       = fragments
      @tags            = tags
    end

    attr_reader :hash
    attr_accessor :chapter_section

    def id
      @id ||= hash.fetch('id') { |key|
        raise "Page is missing #{key}"
      }
    end

    def url
      @url ||= OpenStax::Cnx::V1.url_for(id)
    end

    # Use the title in the collection hash
    def title
      @title ||= hash.fetch('title') { |key|
        raise "Page id=#{id} is missing #{key}"
      }
    end

    def is_intro?
      return @is_intro unless @is_intro.nil?
      # CNX plans to implement a better way to identify chapter intro pages
      # This is a hack to be used until that happens
      @is_intro = title.start_with?('Introduction')
    end

    def full_hash
      @full_hash ||= OpenStax::Cnx::V1.fetch(id)
    end

    def content
      @content ||= full_hash.fetch('content') { |key| raise "Page id=#{id} is missing #{key}" }
    end

    def doc
      @doc ||= Nokogiri::HTML(content)
    end

    def root
      @root ||= doc.at_css(ROOT_CSS)
    end

    # Changes relative url attributes in the doc to be absolute
    # Changes http embedded scripts/images/iframes to https
    def converted_doc
      # In the future, change to point to reference material within Tutor
      return @converted_doc unless @converted_doc.nil?

      @converted_doc = doc.dup

      @converted_doc.css("[src]").each do |link|
        src = link.attributes["src"]
        uri = Addressable::URI.parse(src.value)

        if uri.absolute?
          # Since this is embedded content, make sure it is https
          uri.scheme = "https"
          src.value = uri.to_s
        else
          next if uri.path.blank?

          # Relative link: make secure and absolute
          src.value = OpenStax::Cnx::V1.url_for(uri, secure: true)
        end
      end

      @converted_doc.css("[href]").each do |link|
        href = link.attributes["href"]
        uri = Addressable::URI.parse(href.value)

        # Anchors don't need to be https
        next if uri.absolute? || uri.path.blank?

        # Relative link: make secure and absolute
        href.value = OpenStax::Cnx::V1.url_for(uri, secure: true)
      end

      @converted_doc
    end

    def converted_content
      @converted_content ||= converted_doc.to_html
    end

    def converted_root
      @converted_root ||= converted_doc.at_css(ROOT_CSS)
    end

    def fragments
      return @fragments unless @fragments.nil?

      root_copy = converted_root.dup
      root_copy.css(DISCARD_CSS).remove

      @fragments = split_into_fragments(root_copy)
    end

    def los
      @los ||= tags.select{ |tag| tag[:type] == :lo }.collect{ |tag| tag[:value] }
    end

    def aplos
      @aplos ||= tags.select{ |tag| tag[:type] == :aplo }.collect{ |tag| tag[:value] }
    end

    def tags
      return @tags.values unless @tags.nil?

      @tags = {}

      # Extract tag name and description from .ost-standards-def and .os-learning-objective-def.

      # LO tags
      root.css(LO_DEF_NODE_CSS).each do |node|
        klass = node.attr('class')
        lo_value = LO_REGEX.match(klass).try(:[], 1)
        next if lo_value.nil?

        teks_value = TEKS_REGEX.match(klass).try(:[], 1)
        description = node.content.strip

        @tags[lo_value] = {
          value: lo_value,
          description: description,
          teks: teks_value,
          type: :lo
        }
      end

      # Other standards
      root.css(STD_DEF_NODE_CSS).each do |node|
        klass = node.attr('class')
        name = node.at_css(STD_NAME_NODE_CSS).try(:content).try(:strip)
        description = node.at_css(STD_DESC_NODE_CSS).try(:content).try(:strip)
        value = nil

        if node.matches?(TEKS_DEF_NODE_CSS)
          value = TEKS_REGEX.match(klass).try(:[], 1)
          type = :teks
        elsif node.matches?(APBIO_DEF_NODE_CSS)
          # Hack - Remove when we have another way to determine chapter/section for AP LO's
          # Get book, chapter and section from first LO (for bio)
          hack = /([\w+-]+)-lo[\d]+/.match(@tags.values.first[:value]).try(:[], 1) || 'apbio'
          value = APLO_REGEX.match(klass).try(:[], 1)
          value = "#{hack}-aplo-#{value}" unless value.nil?
          type = :aplo
        end

        next if value.nil?

        @tags[value] = {
          value: value,
          name: name,
          description: description,
          type: type
        }
      end

      @tags.values
    end

    def visit(visitor:, depth: 0)
      visitor.pre_order_visit(elem: self, depth: depth)
      visitor.in_order_visit(elem: self, depth: depth)
      fragments.each do |fragment|
        fragment.visit(visitor: visitor, depth: depth+1)
      end
      visitor.post_order_visit(elem: self, depth: depth)
    end

  end
end
