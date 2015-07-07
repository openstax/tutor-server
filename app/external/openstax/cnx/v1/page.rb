module OpenStax::Cnx::V1
  class Page

    include HtmlTreeOperations

    # Start parsing here
    ROOT_CSS = 'html > body'

    # Remove completely
    DISCARD_CSS = '.ost-reading-discard, .os-teacher, [data-type="glossary"]'

    # Just a page break
    ASSESSED_FEATURE_CLASS = 'ost-assessed-feature'

    # Just a page break
    FEATURE_CLASS = 'ost-feature'

    # Exercise choice fragment
    EXERCISE_CHOICE_CLASS = 'ost-exercise-choice'

    # Exercise fragment
    EXERCISE_CLASS = 'os-exercise'

    # Interactive fragment
    INTERACTIVE_CLASSES = ['os-interactive', 'ost-interactive']

    # Video fragment
    VIDEO_CLASS = 'ost-video'

    # Split fragments on these
    SPLIT_CSS = [ASSESSED_FEATURE_CLASS, FEATURE_CLASS, EXERCISE_CHOICE_CLASS,
                 EXERCISE_CLASS, INTERACTIVE_CLASSES, VIDEO_CLASS].flatten
                                                                  .collect{ |c| ".#{c}" }
                                                                  .join(', ')

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

    def fragments
      return @fragments unless @fragments.nil?

      root_copy = converted_root.dup
      root_copy.css(DISCARD_CSS).remove

      @fragments = split_into_fragments(root_copy)
    end

    def visit(visitor:, depth: 0)
      visitor.pre_order_visit(elem: self, depth: depth)
      visitor.in_order_visit(elem: self, depth: depth)
      fragments.each do |fragment|
        fragment.visit(visitor: visitor, depth: depth+1)
      end
      visitor.post_order_visit(elem: self, depth: depth)
    end

    protected

    def node_to_fragment(node)
      klass = node['class'] || []

      fragment =
        if INTERACTIVE_CLASSES.any? { |interactive_class| klass.include?(interactive_class) }
          Fragment::Interactive.new(node: node)
        elsif klass.include?(VIDEO_CLASS)
          Fragment::Video.new(node: node)
        elsif klass.include?(EXERCISE_CHOICE_CLASS)
          Fragment::ExerciseChoice.new(node: node)
        elsif klass.include?(EXERCISE_CLASS)
          Fragment::Exercise.new(node: node)
        else
          Fragment::Text.new(node: node)
        end

      fragment.add_labels('worked-example') if klass.include?('worked-example')
      fragment
    end

    def split_into_fragments(node)
      fragments = []

      # Initialize current_node
      current_node = node

      # Find first split
      split = current_node.at_css(SPLIT_CSS)

      # Split the root and collect the TaskStep attributes
      while !split.nil? do
        klass = split['class']

        if klass.include?(ASSESSED_FEATURE_CLASS) || klass.include?(FEATURE_CLASS)
          # Feature or Assessed Feature: do a recursive split
          splitting_fragments = split_into_fragments(split)
        else
          # Get a single fragment for the given node
          splitting_fragments = [node_to_fragment(split)]
        end

        # Copy the node content and find the same split CSS in the copy
        next_node = current_node.dup
        split_copy = next_node.at_css(SPLIT_CSS)

        # One copy retains the content before the split;
        # the other retains the content after the split
        remove_after(split, current_node)
        remove_before(split_copy, next_node)

        # Remove the splits and any empty parents
        recursive_compact(split, current_node)
        recursive_compact(split_copy, next_node)

        # Create text fragment before current split
        unless current_node.content.blank?
          fragments << node_to_fragment(current_node)
        end

        # Add contents from splitting fragments
        fragments += splitting_fragments

        current_node = next_node
        split = current_node.at_css(SPLIT_CSS)
      end

      # Create text fragment after all splits
      unless current_node.content.blank?
        fragments << node_to_fragment(current_node)
      end

      fragments
    end

  end
end
