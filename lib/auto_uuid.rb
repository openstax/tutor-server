module AutoUuid
  module ActiveRecord
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def auto_uuid(column = :uuid)
        generator_method = "generate_#{column}".to_sym

        class_exec do
          validates column, presence: true, uniqueness: true

          after_initialize generator_method

          protected

          define_method(generator_method) do
            send("#{column}=", SecureRandom.uuid) if new_record? && send(column).blank?
          end
        end
      end
    end
  end
end

ActiveRecord::Base.send :include, AutoUuid::ActiveRecord
