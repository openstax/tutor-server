class OpenStax::Content::Page
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

    feature_id_css = feature_ids.map { |feature_id| "##{feature_id}" }.join(', ')
    node.at_css(feature_id_css)
  end

  def initialize(book: nil, hash: {}, uuid: nil, url: nil, title: nil, content: nil)
    @uuid    = uuid || hash['id']&.split('@', 2)&.first
    raise ArgumentError, 'Either uuid or hash with id key is required' if @uuid.nil?

    @book    = book
    @hash    = hash
    @url     = url
    @title   = title || hash['title']
    @content = content
  end

  attr_accessor :chapter_section
  attr_reader :uuid, :hash

  def book
    raise ArgumentError, 'Book was not specified' if @book.nil?

    @book
  end

  def url
    @url ||= "#{book.url_fragment}:#{uuid}.json"
  end

  def parsed_title
    @parsed_title ||= OpenStax::Content::Title.new @title
  end

  def book_location
    parsed_title.book_location
  end

  def title
    parsed_title.text
  end

  def full_hash
    @full_hash ||= book.archive.json url
  end

  def short_id
    @short_id ||= full_hash.fetch('shortId', nil)
  end

  def content
    @content ||= full_hash.fetch('content')
  end

  def doc
    @doc ||= Nokogiri::HTML(content)
  end

  def root
    @root ||= doc.at_css(ROOT_CSS)
  end

  def footnotes
    @footnotes ||= doc.css('[role=doc-footnote]')
  end

  # Replaces links to embeddable sims (and maybe videos in the future) with iframes
  # Changes exercise urls in the doc to be absolute
  def convert_content!
    OpenStax::Content::Fragment::Interactive.replace_interactive_links_with_iframes!(doc)
    OpenStax::Content::Fragment::Exercise.absolutize_exercise_urls!(doc)
    map_note_format!(doc)
    @content = doc.to_html
    @root = nil
  end

  def snap_lab_nodes
    root.css(SNAP_LAB_CSS)
  end

  def snap_lab_title(snap_lab)
    snap_lab.at_css(SNAP_LAB_TITLE_CSS).try(:text)
  end

  def los
    @los ||= tags.select { |tag| tag[:type] == :lo }.map { |tag| tag[:value] }
  end

  def aplos
    @aplos ||= tags.select { |tag| tag[:type] == :aplo }.map { |tag| tag[:value] }
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

  # Adds a container div around note content for styling
  def map_note_format!(node)
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
  end
end
