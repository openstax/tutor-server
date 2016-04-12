module OpenStax::Cnx::V1
  class Fragment::Reading < Fragment

    def to_html
      @to_html ||= node.to_html
    end

    def blank?
      to_html.blank?
    end

  end
end
