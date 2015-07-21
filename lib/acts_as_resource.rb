module ActsAsResource
  module ActiveRecord
    module Base
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def acts_as_resource(options = {})
          class_exec do
            validates :url, presence: true unless options[:allow_nil]
            validates :url, uniqueness: true, allow_nil: options[:allow_nil] unless options[:url_not_unique]

            def content
              # TODO: Caching
              super
            end
          end
        end
      end
    end

    module ConnectionAdapters
      module TableDefinition
        # Adds resource fields on table creation
        def resource(options = {})
          string :url, null: options[:allow_nil]
          text :content
        end

        # Adds resource index after table creation
        def resource_index(options = {})
          index :url, unique: true unless options[:url_not_unique]
        end
      end
    end
  end
end

ActiveRecord::Base.send :include, ActsAsResource::ActiveRecord::Base
ActiveRecord::ConnectionAdapters::TableDefinition.send(
  :include, ActsAsResource::ActiveRecord::ConnectionAdapters::TableDefinition
)
