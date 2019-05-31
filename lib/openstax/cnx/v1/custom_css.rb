module OpenStax::Cnx::V1
  class CustomCss
    include Singleton

    define_method(:'has-descendants') do |node_set, selector, number = 1|
      node_set.select { |node| node.css(selector).size >= number }
    end
  end
end
