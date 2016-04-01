module OpenStax::Cnx::V1::Fragment
  class Feature
    include ActsAsFragment

    def initialize(node:, fragment_splitter:)
      @node = node
    end

    attr_reader :node

    def title
      @title ||= fragments.first.title
    end

    def fragments
      @fragments ||= fragment_splitter.split_into_fragments(node, true)
    end

    def to_html
      node.to_html
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
