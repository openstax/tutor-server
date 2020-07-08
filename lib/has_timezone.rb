module HasTimezone
  module ActiveRecord
    module Base
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def has_timezone(*args)
          options = args.last.is_a?(Hash) ? args.pop : {}

          args.each do |method_name|
            field_name = method_name
            field_name = "#{options[:prefix]}_#{field_name}" if options.has_key?(:prefix)
            field_name = "#{field_name}_#{options[:suffix]}" if options.has_key?(:suffix)
            field_setter = "#{field_name}=".to_sym
            field_changed = "#{field_name}_changed?".to_sym

            include(
              Module.new do
                # Read timezone-less value from DB and apply the current timezone to it
                define_method(method_name.to_sym) do
                  datetime = send field_name
                  datetime.nil? ? nil : DateTimeUtilities.apply_tz(datetime, time_zone)
                end

                # Drop any timezones given, then write the result to the DB
                define_method("#{method_name}=".to_sym) do |value|
                  datetime = value.is_a?(String) ? DateTimeUtilities.from_s(value) :
                                                   value.try(:to_datetime)

                  send field_setter, DateTimeUtilities.remove_tz(datetime)
                end

                define_method("#{method_name}_changed?".to_sym) do
                  send field_changed
                end if field_name != method_name
              end
            )
          end
        end
      end
    end
  end
end

ActiveRecord::Base.send :include, HasTimezone::ActiveRecord::Base
