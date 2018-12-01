module OpenStax::Cnx::V1
  class Page

    # Start parsing here
    ROOT_CSS = 'html > body'

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

    def self.feature_node(node, feature_ids)
      feature_ids = [feature_ids].flatten
      return if feature_ids.empty?

      feature_id_css = feature_ids.map{ |feature_id| "##{feature_id}" }.join(', ')
      node.at_css(feature_id_css)
    end

    def initialize(hash: {}, id: nil, url: nil, title: nil, content: nil, book: nil)
      @hash    = hash
      @id      = id
      @url     = url
      @title   = title
      @content = content
      @book = book
    end

    attr_accessor :chapter_section
    attr_reader :hash, :book

    def book_location
      @book_location ||= (
       (parsed_title[:book_location].present? && parsed_title[:book_location].split('.')) || []
      )
    end

    def id
      @id ||= hash.fetch('id') { |key| raise "Page is missing #{key}" }
    end

    def url
      @url ||= url_for(id)
    end

    # Use the title in the collection hash
    def title
      @title ||= parsed_title[:text]
    end

    def parsed_title
      @parsed_title ||= OpenStax::Cnx::V1.parse_baked_title(
        hash.fetch('title') { |key|
          raise "#{self.class.name} id=#{id} is missing #{key}"
        }
      )
    end

    def is_intro?
      return @is_intro unless @is_intro.nil?
      # CNX plans to implement a better way to identify chapter intro pages
      # This is a hack to be used until that happens
      @is_intro = title.start_with?('Introduction')
    end

    def full_hash
      @full_hash ||= OpenStax::Cnx::V1.fetch(url)
    end

    def uuid
      @uuid ||= full_hash.fetch('id') { |key| raise "Book id=#{id} is missing #{key}" }
    end

    def short_id
      @short_id ||= full_hash.fetch('shortId', nil)
    end

    def version
      @version ||= full_hash.fetch('version') { |key| raise "Book id=#{id} is missing #{key}" }
    end

    def canonical_url
      @canonical_url ||= url_for("#{uuid}@#{version}")
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

    # Replaces links to embeddable sims (and maybe videos in the future) with iframes
    # Changes exercise urls and relative urls in the doc to be absolute
    # Changes any embedded http url (in a src attribute) to https
    def converted_doc
      # In the future, change CNX URLs to point to reference material within Tutor
      @converted_doc ||= begin
        cd = doc.dup
        cd = OpenStax::Cnx::V1::Fragment::Interactive.replace_interactive_links_with_iframes(cd)
        cd = absolutize_and_secure_urls(cd)
        map_note_format(cd)
      end
    end

    def converted_content
      @converted_content ||= converted_doc.to_html
    end

    def converted_root
      @converted_root ||= converted_doc.at_css(ROOT_CSS)
    end

    def snap_lab_nodes
      converted_root.css(SNAP_LAB_CSS)
    end

    def snap_lab_title(snap_lab)
      snap_lab.at_css(SNAP_LAB_TITLE_CSS).try(:text)
    end

    def los
      @los ||= tags.select{ |tag| tag[:type] == :lo }.map{ |tag| tag[:value] }
    end

    def aplos
      @aplos ||= tags.select{ |tag| tag[:type] == :aplo }.map{ |tag| tag[:value] }
    end

    def tags
      return @tags.values unless @tags.nil?

      # Start with default cnxmod tag
      cnxmod_value = "context-cnxmod:#{uuid}"
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

    protected

    def url_for(path)
      book.nil? ? OpenStax::Cnx::V1.archive_url_for(path) : "#{book.canonical_url}:#{path}"
    end

    # add container div around note content for styling
    def map_note_format(node)
      note_selector = <<-eos
        .note:not(.learning-objectives),
        .example,
        .grasp-check,
        [data-type="note"],
        [data-element-type="check-understanding"]
      eos

      note_selector = note_selector.gsub(/\s+/, "")

      node.css(note_selector).each do |note|
        note.set_attribute('data-tutor-transform', true)
        body = Nokogiri::XML::Node.new('div', doc)
        body.set_attribute('data-type', 'content')

        content = note.css('>*:not([data-type=title])')
        content.unlink()

        body.children = content
        note.add_child(body)
      end

      node
    end

    def absolutize_and_secure_urls(node)
      # Absolutize exercise urls
      node = OpenStax::Cnx::V1::Fragment::Exercise.absolutize_exercise_urls(node.dup)

      # Absolutize embed urls
      node.css("[src]").each do |link|
        src = link.attributes["src"]
        uri = Addressable::URI.parse(src.value) rescue nil

        # Skip invalid links
        if uri.nil?
          Rails.logger.warn { "Invalid embed url: \"#{src.value}\" when parsing page: #{url}" }
          next
        end

        if uri.absolute?
          # Absolute link: make secure (since this is embedded content)

          uri.scheme = "https"
          src.value = uri.to_s
        else
          # Relative link: make secure and absolute

          # Skip anchor-only links
          next if uri.path.blank?

          src.value = OpenStax::Cnx::V1.webview_url_for(uri)
        end
      end

      # Absolutize link urls
      node.css("[href]").each do |link|
        href = link.attributes["href"]
        uri = Addressable::URI.parse(href.value) rescue nil

        # Skip invalid links
        if uri.nil?
          Rails.logger.warn { "Invalid link url: \"#{href.value}\" when parsing page: #{url}" }
          next
        end

        # Modify only valid relative links that are not anchor-only
        next if uri.absolute? || uri.path.blank?

        # Relative link: make secure and absolute
        href.value = OpenStax::Cnx::V1.webview_url_for(uri)
      end

      node
    end

  end
end
