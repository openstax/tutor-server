module Settings
  module Highlighting

    class << self

      def is_allowed
        Settings::Db.store.is_highlighting_allowed
      end

    end

  end
end
