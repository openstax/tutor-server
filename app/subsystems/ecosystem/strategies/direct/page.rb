module Ecosystem
  module Strategies
    class Direct
      class Page < Entity

        wraps ::Content::Models::Page

        exposes :title

      end
    end
  end
end
