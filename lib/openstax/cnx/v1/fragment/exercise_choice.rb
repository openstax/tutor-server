module OpenStax::Cnx::V1::Fragment
  class ExerciseChoice
    include ActsAsFragment

    # Used to get the title
    TITLE_CSS = '[data-type="title"]'

    # For fragments missing a proper title
    DEFAULT_TITLE = nil

    attr_reader :exercise_css

    def initialize(node:, exercise_css:, title: nil, exercise_fragments: nil)
      @node               = node
      @exercise_css       = exercise_css
      @title              = title
      @exercise_fragments = exercise_fragments
      add_labels('worked-example') if self.exercise_fragments.empty?
    end

    attr_reader :node

    def title
      @title ||= node.at_css(TITLE_CSS).try(:content).try(:strip) || DEFAULT_TITLE
    end

    def exercise_fragments
      @exercise_fragments ||= node.css(exercise_css).map do |ex_node|
        Exercise.new(node: ex_node)
      end
    end

    def exercise?
      true
    end

    protected

    def custom_visit(visitor:, depth:)
      exercise_fragments.each do |exercise_fragment|
        exercise_fragment.visit(visitor: visitor, depth: depth+1)
      end
    end

  end
end
