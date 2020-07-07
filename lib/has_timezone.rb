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
            instance_variable_name = "@#{method_name}".to_sym
            clear_cache_method = "clear_#{method_name}_cache".to_sym
            field_setter = "#{field_name}=".to_sym
            reload_method = "reload_without_#{method_name}_caching".to_sym

            include(
              Module.new do
                # Read timezone-less value from DB and apply the current timezone to it
                define_method(method_name.to_sym) do
                  value = instance_variable_get instance_variable_name
                  return value unless value.nil?

                  datetime = send field_name
                  return if datetime.nil?

                  instance_variable_set instance_variable_name,
                                        DateTimeUtilities.apply_tz(datetime, time_zone)
                end

                define_method(clear_cache_method) do
                  instance_variable_set instance_variable_name, nil
                end

                define_method(field_setter) do |value|
                  send clear_cache_method

                  super value
                end

                # Drop any timezones given, then write the result to the DB
                define_method("#{method_name}=".to_sym) do |value|
                  datetime = value.is_a?(String) ? DateTimeUtilities.from_s(value) :
                                                   value.try(:to_datetime)

                  send field_setter, DateTimeUtilities.remove_tz(datetime)
                end

                define_method(:reload) do |*args|
                  send clear_cache_method

                  super *args
                end

                define_method("#{method_name}_changed?".to_sym) do
                  send "#{field_name}_changed?".to_sym
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
