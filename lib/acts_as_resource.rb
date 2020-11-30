module ActsAsResource
  module ActiveRecord
    module Base
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def acts_as_resource
          class_exec do
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
        def resource
          string :url, null: false
          text :content
        end

        # Adds resource index after table creation
        def resource_index
          index :url
        end
      end
    end
  end
end

ActiveRecord::Base.send :include, ActsAsResource::ActiveRecord::Base
ActiveRecord::ConnectionAdapters::TableDefinition.send(
  :include, ActsAsResource::ActiveRecord::ConnectionAdapters::TableDefinition
)
