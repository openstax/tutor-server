module OpenStax::Cnx::V1::Visitors::Book
  VISIT_TYPES = %i{pre in post}
  ELEM_CLASSES = [OpenStax::Cnx::V1::Book,
                  OpenStax::Cnx::V1::BookPart,
                  OpenStax::Cnx::V1::Page,
                  OpenStax::Cnx::V1::Fragments::Text,
                  OpenStax::Cnx::V1::Fragments::Exercise,
                  OpenStax::Cnx::V1::Fragments::ExerciseChoice,
                  OpenStax::Cnx::V1::Fragments::Interactive,
                  OpenStax::Cnx::V1::Fragments::Video]

  def self.elem_type(elem_class)
    elem_class.name.underscore.remove("openstax/cnx/v1/").gsub('/', '_')
  end
  ELEM_TYPES = ELEM_CLASSES.collect{|ec| self.elem_type(ec)}

  ## Define top-level visit methods which delegate to class-specific
  ## visit methods.  For example:
  ##   def pre_order_visit(elem:, depth:)
  ##     case elem
  ##     when OpenStax::Cnx::V1::Book
  ##       pre_order_visit_book(book: elem, depth: depth)
  ##     [other elem when clauses]
  ##     else
  ##       raise "unknown element type: #{elem.class.name}"
  ##     end
  ##   end
  VISIT_TYPES.each do |visit_type|
    when_blocks = ELEM_CLASSES.collect do |elem_class|
      elem_type = self.elem_type(elem_class)
      <<-EOS
      when #{elem_class}
        #{visit_type}_order_visit_#{elem_type}(#{elem_type}: elem, depth: depth)
      EOS
    end.join
    method_body = <<-EOS
    def #{visit_type}_order_visit(elem:, depth:)
      case elem
      #{when_blocks}
      else
        raise "unknown element type: \#{elem.class.name}"
      end
    end
    EOS
    module_eval(method_body, __FILE__, __LINE__)
  end

  ## Define default, empty visit methods which do nothing, so that classes which
  ## mixin this module only need to define the ones they want to override.
  VISIT_TYPES.each do |visit_type|
    ELEM_TYPES.each do |elem_type|
      method_body = <<-EOS
      def #{visit_type}_order_visit_#{elem_type}(#{elem_type}:, depth:)
      end
      EOS
      module_eval(method_body, __FILE__, __LINE__)
    end
  end

end
