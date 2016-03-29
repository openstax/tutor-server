module OpenStax::Cnx::V1
  class Page

    include FragmentSplitter

    # Start parsing here
    ROOT_CSS = 'html > body'

    # Remove completely
    DISCARD_CSS = '.ost-reading-discard, .os-teacher, [data-type="glossary"]'

    # Find snap lab notes
    SNAP_LAB_CSS = '.snap-lab'
    SNAP_LAB_TITLE_CSS = '[data-type="title"]'

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

    def initialize(hash: {}, id: nil, title: nil, content: nil)
      @hash            = hash
      @id              = id
      @title           = title
      @content         = content
    end

    attr_reader :hash
    attr_accessor :chapter_section

    def id
      @id ||= hash.fetch('id') { |key|
        raise "Page is missing #{key}"
      }
    end

    def url
      @url ||= OpenStax::Cnx::V1.archive_url_for(id)
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

    def uuid
      @uuid ||= full_hash.fetch('id') { |key|
        raise "Book id=#{id} is missing #{key}"
      }
    end

    def version
      @version ||= full_hash.fetch('version') { |key|
        raise "Book id=#{id} is missing #{key}"
      }
    end

    def canonical_url
      @canonical_url ||= OpenStax::Cnx::V1.archive_url_for("#{uuid}@#{version}")
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
          # Skip the special anchor-only exercise tags
          next if uri.path.blank?

          # Relative link: make secure and absolute
          src.value = OpenStax::Cnx::V1.archive_url_for(uri)
        end
      end

      @converted_doc.css("[href]").each do |link|
        href = link.attributes["href"]
        uri = Addressable::URI.parse(href.value)

        # Anchors don't need to be https
        next if uri.absolute? || uri.path.blank?

        # Relative link: make secure and absolute
        href.value = OpenStax::Cnx::V1.archive_url_for(uri)
      end

      # Absolutize exercise links
      @converted_doc.css(".#{EXERCISE_CLASS}").each do |exercise|
        Fragment::Exercise.absolutize_url(exercise)
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

    def snap_labs
      converted_root.css(SNAP_LAB_CSS).collect { |snap_lab|
        {
          id: snap_lab.attr('id'),
          title: snap_lab.at_css(SNAP_LAB_TITLE_CSS).try(:text),
          fragments: split_into_fragments(snap_lab)
        }
      }
    end

    def los
      @los ||= tags.select{ |tag| tag[:type] == :lo }.collect{ |tag| tag[:value] }
    end

    def aplos
      @aplos ||= tags.select{ |tag| tag[:type] == :aplo }.collect{ |tag| tag[:value] }
    end

    def tags
      return @tags.values unless @tags.nil?

      # Start with default cnxmod tag
      cnxmod_value = "cnxmod:#{uuid}"
      @tags = { cnxmod_value => { value: cnxmod_value, type: :cnxmod } }

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
          value = LO_REGEX.match(klass).try(:[], 1)
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
