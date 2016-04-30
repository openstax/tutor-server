module Axlsx
  class Comments < SimpleTypedList
    def authors
      [""]
    end
  end

  class Comment
    def author_index
      0
    end
  end
end
