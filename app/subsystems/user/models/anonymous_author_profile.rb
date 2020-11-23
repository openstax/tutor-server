module User
  module Models
    class AnonymousAuthorProfile
      ID = -1

      def self.id
        ID
      end

      def self.name
        'OpenStax Community'
      end
    end
  end
end
