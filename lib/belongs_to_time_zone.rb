module BelongsToTimeZone
  module ActiveRecord
    module Base
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def belongs_to_time_zone(*args)
          options = args.last.is_a?(Hash) ? args.pop : {}

          association_options = options.except(:default, :prefix, :suffix)

          class_exec do
            belongs_to :time_zone, association_options.merge(subsystem: :none)

            if options[:default].present?
              define_method :time_zone do |*args|
                super(*args) || self.time_zone = ::TimeZone.new(name: options[:default])
              end

              before_validation :time_zone
            end

            define_time_zone_methods(args, options)
          end
        end

        protected

        def define_time_zone_methods(args, options)
          args.each do |method_name|
            field_name = method_name
            field_name = "#{options[:prefix]}_#{field_name}" if options[:prefix]
            field_name = "#{field_name}_#{options[:suffix]}" if options[:suffix]

            # Read time_zone-less value from DB and apply the current time_zone to it
            define_method(method_name) do
              datetime = read_attribute(field_name)
              next nil if datetime.nil?
              # Use server's time_zone (Time.zone) if no time_zone available
              tz = time_zone.try(:to_tz) || Time.zone

              DateTimeUtilities.apply_tz(datetime, tz)
            end

            # Drop any time_zones given, then write the result to the DB
            define_method("#{method_name}=") do |value|
              datetime = value.is_a?(String) ? DateTimeUtilities.from_s(value) :
                                               value.try(:to_datetime)

              write_attribute(field_name, DateTimeUtilities.remove_tz(datetime))
            end

            if field_name != method_name
              define_method("#{method_name}_changed?") do
                send("#{field_name}_changed?") || time_zone_id_changed?
              end
            end
          end
        end
      end
    end
  end
end

ActiveRecord::Base.send :include, BelongsToTimeZone::ActiveRecord::Base
