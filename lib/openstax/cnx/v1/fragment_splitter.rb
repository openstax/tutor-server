module OpenStax::Cnx::V1
  class FragmentSplitter

    include HtmlTreeOperations

    attr_reader :split_reading_css, :split_video_css, :split_interactive_css,
                :split_required_exercise_css, :split_optional_exercise_css,
                :discard_css, :split_css


    def initialize(hash)
      reading_css_array = hash[:split_reading_css].to_a
      @split_reading_css = reading_css_array.join(', ')
      video_css_array = hash[:split_video_css].to_a
      @split_video_css = video_css_array.join(', ')
      interactive_css_array = hash[:split_interactive_css].to_a
      @split_interactive_css = interactive_css_array.join(', ')
      required_exercise_css_array = hash[:split_required_exercise_css]
      @split_required_exercise_css = required_exercise_css_array.join(', ')
      optional_exercise_css_array = hash[:split_optional_exercise_css]
      @split_optional_exercise_css = optional_exercise_css_array.join(', ')
      @discard_css = hash[:discard_css].to_a.join(', ')
      @split_css = (reading_css_array + video_css_array + interactive_css_array +
                    required_exercise_css_array + optional_exercise_css_array).uniq.join(', ')
    end

    def dup_and_remove_discarded_css(node)
      node_copy = node.dup
      node_copy.css(discard_css).remove unless discard_css.blank?
    end

    def split_into_fragments(node, skip_feature = false)
      return [] if split_css.blank?

      fragments = []

      # Initialize current_node
      current_node = node

      # Find first split
      split = current_node.at_css(split_css)

      # Split the root and collect the TaskStep attributes
      while !split.nil? do
        # Get a single fragment for the given node
        splitting_fragment = node_to_fragment(split, skip_feature)

        # Copy the node content and find the same split CSS in the copy
        next_node = current_node.dup
        split_copy = next_node.at_css(split_css)

        # One copy retains the content before the split;
        # the other retains the content after the split
        remove_after(split, current_node)
        remove_before(split_copy, next_node)

        # Remove the splits and any empty parents
        recursive_compact(split, current_node)
        recursive_compact(split_copy, next_node)

        # Create text fragment before current split
        unless current_node.content.blank?
          fragments << node_to_fragment(current_node, skip_feature)
        end

        # Add contents from splitting fragments
        fragments << splitting_fragment

        current_node = next_node
        split = current_node.at_css(split_css)
      end

      # Create text fragment after all splits
      unless current_node.content.blank?
        fragments << node_to_fragment(current_node, skip_feature)
      end

      fragments
    end

    protected

    def node_to_fragment(node, skip_feature)
      if !skip_feature && split_reading_css.present? && node.matches?(split_reading_css)
        Fragment::Feature.new(node: node, fragment_splitter: self)
      elsif split_video_css.present? && node.matches?(split_video_css)
        Fragment::Video.new(node: node)
      elsif split_interactive_css.present? && node.matches?(split_interactive_css)
        Fragment::Interactive.new(node: node)
      elsif split_required_exercise_css.present? && node.matches?(split_required_exercise_css)
        Fragment::Exercise.new(node: node)
      elsif split_optional_exercise_css.present? && node.matches?(split_optional_exercise_css)
        Fragment::ExerciseChoice.new(node: node, exercise_css: split_required_exercise_css)
      else
        Fragment::Text.new(node: node)
      end
    end

  end
end
