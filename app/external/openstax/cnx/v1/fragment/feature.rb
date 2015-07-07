module OpenStax::Cnx::V1::Fragment
  class Feature
    include ActsAsFragment
    include OpenStax::Cnx::V1::FragmentSplitter

    def initialize(node:)
      @node = node
    end

    attr_reader :node

    def title
      @title ||= fragments.first.title
    end

    def fragments
      @fragments ||= split_into_fragments(node)
    end

    def to_html
      node.to_html
    end
  end
end
