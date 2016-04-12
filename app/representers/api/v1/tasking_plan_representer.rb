module Api::V1
  class TaskingPlanRepresenter < Roar::Decorator

    include Roar::JSON
    include Representable::Coercion

    TARGET_TYPE_TO_API_MAP = { 'CourseMembership::Models::Period' => 'period',
                               'Entity::Course' => 'course' }
    TARGET_TYPE_TO_CLASS_MAP = { 'period' => 'CourseMembership::Models::Period',
                                 'course' => 'Entity::Course' }

    property :target_id,
             type: String,
             readable: true,
             writeable: true,
             schema_info: {
               required: true
             }

    property :target_type,
             type: String,
             readable: true,
             writeable: true,
             getter: ->(*) { TARGET_TYPE_TO_API_MAP[target_type] },
             setter: ->(val, *) { self.target_type = TARGET_TYPE_TO_CLASS_MAP[val] },
             schema_info: {
               required: true
             }

    property :opens_at,
             type: String,
             readable: true,
             writeable: true,
             getter: ->(*) { DateTimeUtilities.to_api_s(opens_at) },
             setter: ->(val, *) { self.opens_at = TaskingPlanRepresenter.opens_at_from_api_s(val) },
             schema_info: {
               required: true
             }

    property :due_at,
             type: String,
             readable: true,
             writeable: true,
             getter: ->(*) { DateTimeUtilities.to_api_s(due_at) },
             setter: ->(val, *) { self.due_at = TaskingPlanRepresenter.due_at_from_api_s(val) },
             schema_info: {
               required: true
             }


    def self.opens_at_from_api_s(time_str)
      time_zone = ActiveSupport::TimeZone['Central Time (US & Canada)']
      orig_time = time_zone.parse(extract_date_portion(time_str))
      new_time  = orig_time.nil? ? nil : orig_time.in_time_zone(time_zone).midnight + 1.minute
      new_time
    end

    def self.due_at_from_api_s(time_str)
      time_zone = ActiveSupport::TimeZone['Central Time (US & Canada)']
      orig_time = time_zone.parse(extract_date_portion(time_str))
      new_time  = orig_time.nil? ? nil : orig_time.in_time_zone(time_zone).midnight + 7.hours
      new_time
    end

    def self.extract_date_portion(string)
      results1 = /\b(\d\d\d\d)-(\d\d)-(\d\d)\b/.match(string)
      results2 = /\b(\d\d\d\d)-(\d\d)-(\d\d)T\d\d:\d\d:\d\d/.match(string)
      results3 = /\b(\d\d\d\d)(\d\d)(\d\d)\b/.match(string)
      results4 = /\b(\d\d\d\d)(\d\d)(\d\d)T\d\d:\d\d:\d\d/.match(string)

      captures = [results1, results2, results3, results4].map(&:to_a).reduce(:+)

      raise "string contains no date portions (#{string})" \
        if captures.count == 0

      raise "string contains multiple date portions (#{string})" \
        if captures.count > 4

      year, month, day = captures[1..3]

      date_portion = "#{year}-#{month}-#{day}"
      date_portion
    end

  end

end
