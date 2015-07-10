module OpenStax::Cnx::V1
  module FragmentSplitter

    include HtmlTreeOperations

    # Just a page break
    FEATURE_CLASSES = ['ost-assessed-feature', 'ost-feature']

    # Exercise choice fragment
    EXERCISE_CHOICE_CLASS = 'ost-exercise-choice'

    # Exercise fragment
    EXERCISE_CLASS = 'os-exercise'

    # Interactive fragment
    INTERACTIVE_CLASSES = ['os-interactive', 'ost-interactive']

    # Video fragment
    VIDEO_CLASS = 'ost-video'

    # Split fragments on these
    SPLIT_CSS = [FEATURE_CLASSES, EXERCISE_CHOICE_CLASS, EXERCISE_CLASS,
                 INTERACTIVE_CLASSES, VIDEO_CLASS].flatten.collect{ |c| ".#{c}" }.join(', ')

    protected

    def node_to_fragment(node, skip_features)
      klass = node['class'] || []

      fragment =
        if FEATURE_CLASSES.any? { |feature_class| klass.include?(feature_class) } && !skip_features
          Fragment::Feature.new(node: node)
        elsif INTERACTIVE_CLASSES.any? { |interactive_class| klass.include?(interactive_class) }
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

    def split_into_fragments(node, skip_features = false)
      fragments = []

      # Initialize current_node
      current_node = node

      # Find first split
      split = current_node.at_css(SPLIT_CSS)

      # Split the root and collect the TaskStep attributes
      while !split.nil? do
        klass = split['class']

        # Get a single fragment for the given node
        splitting_fragment = node_to_fragment(split, skip_features)

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
          fragments << node_to_fragment(current_node, skip_features)
        end

        # Add contents from splitting fragments
        fragments << splitting_fragment

        current_node = next_node
        split = current_node.at_css(SPLIT_CSS)
      end

      # Create text fragment after all splits
      unless current_node.content.blank?
        fragments << node_to_fragment(current_node, skip_features)
      end

      fragments
    end

  end
end
