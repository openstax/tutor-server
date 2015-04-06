module OpenStax::Cnx::V1
  class Page

    include HtmlTreeOperations

    # Start parsing here
    ROOT_CSS = 'html > body'

    # Remove completely
    DISCARD_CSS = '.ost-reading-discard, .os-teacher'

    # Just a page break
    ASSESSED_FEATURE_CSS = '.ost-assessed-feature'

    # Just a page break
    FEATURE_CSS = '.ost-feature'

    # Exercise choice fragment
    EXERCISE_CHOICE_CSS = '.ost-exercise-choice'

    # Exercise fragment
    EXERCISE_CSS = '.os-exercise'

    # Interactive fragment
    INTERACTIVE_CSS = '.ost-interactive'

    # Video fragment
    VIDEO_CSS = '.ost-video'

    # Split fragments on these
    SPLIT_CSS = [ASSESSED_FEATURE_CSS, FEATURE_CSS, EXERCISE_CHOICE_CSS,
                 EXERCISE_CSS, INTERACTIVE_CSS, VIDEO_CSS].join(', ')

    # Find a node with a class that starts with ost-tag-lo-
    LO_CSS = '[class^="ost-tag-lo-"]'

    # Find the LO within the class string and ensure it is properly formatted
    LO_REGEX = /ost-tag-lo-([\w-]+-lo[\d]+)/

    def initialize(hash: {}, path: nil, id: nil, url: nil, title: nil,
                   full_hash: nil, content: nil, los: nil, fragments: nil)
      @hash      = hash
      @path      = path
      @id        = id
      @url       = url
      @title     = title
      @full_hash = full_hash
      @content   = content
      @los       = los
      @fragments = fragments
    end

    attr_reader :hash, :path

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

    def path
      @path ||= hash.fetch('path') { |key|
        raise "Page id=#{id} is missing #{key}"
      }
    end

    def full_hash
      @full_hash ||= OpenStax::Cnx::V1.fetch(id)
    end

    def content
      @content ||= full_hash.fetch('content') { |key|
        raise "Page id=#{id} is missing #{key}"
      }
    end

    def doc
      @doc ||= Nokogiri::HTML(content)
    end

    # Changes relative URL's in the content to be absolute
    def converted_content
      # In the future (when books are readable in Tutor),
      # do the opposite (make absolute links into relative links)
      # and make sure all files are properly served
      doc.css("[src]").each do |tag|
        uri = URI.parse(URI.escape(tag.attributes["src"].value))
        next if uri.absolute?

        tag.attributes["src"].value = URI.unescape(
          OpenStax::Cnx::V1.url_for(uri)
        )
      end

      doc.to_html
    end

    def root
      return @root unless @root.nil?

      @root = doc.at_css(ROOT_CSS)
      @root.css(DISCARD_CSS).remove
      @root
    end

    def los
      @los ||= root.css(LO_CSS).collect do |node|
        LO_REGEX.match(node.attributes['class']).try(:[], 1)
      end.compact.uniq
    end

    def fragments
      return @fragments unless @fragments.nil?

      @fragments = []

      # Initialize current_reading
      current_text = root

      # Find first split
      split = current_text.at_css(SPLIT_CSS)

      # Split the root and collect the TaskStep attributes
      while !split.nil? do
        splitting_fragments = []
        # Figure out what we just split on, testing in priority order
        if split.matches?(ASSESSED_FEATURE_CSS)
          # Assessed Feature = Video + Exercise or Interactive + Exercise or Text + Exercise
          exercise = split.at_css(EXERCISE_CSS)
          Rails.logger.warn { "An assessed feature should have an exercise but doesn't: #{url}" } if exercise.nil?
          recursive_compact(exercise, split) unless exercise.nil?

          if split.matches?(VIDEO_CSS)
            splitting_fragments << Fragment::Video.new(node: split)
          elsif split.matches?(INTERACTIVE_CSS)
            splitting_fragments << Fragment::Interactive.new(node: split)
          else
            splitting_fragments << Fragment::Text.new(node: split)
          end
          splitting_fragments << Fragment::Exercise.new(node: exercise) unless exercise.nil?
        elsif split.matches?(FEATURE_CSS)
          # Text Feature
          splitting_fragments << Fragment::Text.new(node: split)
        elsif split.matches?(EXERCISE_CHOICE_CSS)
          # Exercise choice
          splitting_fragments << Fragment::ExerciseChoice.new(node: split)
        elsif split.matches?(EXERCISE_CSS)
          # Exercise
          splitting_fragments << Fragment::Exercise.new(node: split)
        end

        # Copy the reading content and find the split in the copy
        next_text = current_text.dup
        split_copy = next_text.at_css(SPLIT_CSS)

        # One copy retains the content before the split;
        # the other retains the content after the split
        remove_after(split, current_text)
        remove_before(split_copy, next_text)

        # Remove the splits and any empty parents
        recursive_compact(split, current_text)
        recursive_compact(split_copy, next_text)

        # Create text fragment before current split
        unless current_text.content.blank?
          @fragments << Fragment::Text.new(node: current_text)
        end

        # Add contents from splitting fragments
        @fragments += splitting_fragments

        current_text = next_text
        split = current_text.at_css(SPLIT_CSS)
      end

      # Create text fragment after all splits
      unless current_text.content.blank?
        @fragments << Fragment::Text.new(node: current_text)
      end

      @fragments
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
