module OpenStax::Cnx::V1::Fragment
  module ActsAsFragment
    def visit(visitor:, depth: 0)
      visitor.pre_order_visit(elem: self, depth: depth)
      visitor.in_order_visit(elem: self, depth: depth)
      custom_visit(visitor: visitor, depth: depth)
      visitor.post_order_visit(elem: self, depth: depth)
    end

    def labels
      @labels ||= []
    end

    def add_labels(labels)
      @labels = [@labels, labels].flatten.compact.uniq
    end

    protected

    def custom_visit(visitor:, depth:)
      ## override this to customize visitation
    end
  end
end
