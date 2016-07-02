module OpenStax::Cnx::V1
  class Fragment::Reading < Fragment

    attr_reader :to_html

    def initialize(node:, title: nil, labels: nil)
      super

      @to_html = node.to_html
    end

    def blank?
      to_html.blank?
    end

  end
end
