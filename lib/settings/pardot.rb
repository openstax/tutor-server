module Settings
  module Pardot

    class << self

      def toa_redirect
        Settings::Db.pardot_toa_redirect
      end

      def toa_redirect=(url)
        Settings::Db.pardot_toa_redirect = url
      end

    end

  end
end
