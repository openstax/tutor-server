module User
  module Models
    class AnonymousAuthorProfile
      ID = -1

      def self.id
        ID
      end

      def self.name
        'OpenStax user'
      end
    end
  end
end
