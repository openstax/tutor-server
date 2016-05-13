module BelongsToTimeZone
  module ActiveRecord
    module Base
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def belongs_to_time_zone(*args)
          options = args.last.is_a?(Hash) ? args.pop : {}

          class_exec do
            belongs_to :time_zone, subsystem: :course_profile

            if options[:default].present?
              before_validation :build_time_zone

              define_method(:build_time_zone) do
                self.time_zone ||= CourseProfile::Models::TimeZone.new(name: options[:default])
              end
            end

            args.each do |field|
              # Read time_zone-less value from DB and apply the current time_zone to it
              define_method(field) do
                datetime = read_attribute(field)
                next nil if datetime.nil?
                # Use server's time_zone (Time.zone) if no time_zone available
                zone = time_zone.try(:to_tz) || Time.zone

                # Apply the server's time_zone (without offset)
                # Example: 2 PM UTC -> 2 PM EST
                datetime = datetime.in_time_zone(zone)
                datetime - datetime.utc_offset
              end

              # Drop any time_zones given, then write the result to the DB
              define_method("#{field}=") do |value|
                datetime = case value
                when String
                  DateTime.parse(value) rescue nil
                else
                  value.try(:to_datetime)
                end

                # Drop time_zone if given (and remove its offset)
                # Example: 2 PM EST -> 2 PM UTC
                write_attribute(field, datetime.try(:change, offset: 0).try(:in_time_zone, 'UTC'))
              end
            end
          end
        end
      end
    end
  end
end

ActiveRecord::Base.send :include, BelongsToTimeZone::ActiveRecord::Base
