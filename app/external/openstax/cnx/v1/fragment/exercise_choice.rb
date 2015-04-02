module OpenStax::Cnx::V1::Fragment
  class ExerciseChoice

    # Used to get the title
    TITLE_CSS = '[data-type="title"]'

    # For fragments missing a proper title
    DEFAULT_TITLE = nil

    # Split the exercise fragments on this class
    EXERCISE_CSS = '.os-exercise'

    def initialize(node:, title: nil, exercise_fragments: nil)
      @node       = node
      @title      = title
      @exercise_fragments  = exercise_fragments
    end

    attr_reader :node

    def title
      @title ||= node.at_css(TITLE_CSS).try(:content).try(:strip) || \
                 DEFAULT_TITLE
    end

    def exercise_fragments
      @exercise_fragments ||= node.css(EXERCISE_CSS).collect do |ex_node|
        Exercise.new(node: ex_node)
      end
    end

    def to_s(indent: 0)
      s = "#{' '*indent}EXERCISE CHOICE #{title}\n"
      s << exercise_fragments.collect{|ex| ex.to_s(indent: indent+2)}.join('')
    end

    def visit(visitor:, depth: 0)
      visitor.pre_order_visit(elem: self, depth: depth)
      visitor.in_order_visit(elem: self, depth: depth)
      visitor.post_order_visit(elem: self, depth: depth)
    end

  end
end
