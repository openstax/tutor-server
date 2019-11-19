class Api::V1::Demo::Course::CourseRepresenter < Api::V1::Demo::CourseRepresenter
  # Provide id if the course exists, name otherwise

  property :is_college,
           type: Virtus::Attribute::Boolean,
           readable: true,
           writeable: true

  property :is_test,
           type: Virtus::Attribute::Boolean,
           readable: true,
           writeable: true

  property :term,
           type: String,
           readable: true,
           writeable: true

  property :year,
           type: Integer,
           readable: true,
           writeable: true

  property :starts_at,
           type: String,
           readable: true,
           writeable: true,
           getter: ->(user_options:, decorator:, **) do
             user_options.fetch(:starts_at, starts_at).iso8601
           end

  property :ends_at,
           type: String,
           readable: true,
           writeable: true,
           getter: ->(user_options:, decorator:, **) do
             DateTimeUtilities.relativize(ends_at, starts_at, user_options[:starts_at])
           end

  collection :teachers,
             extend: Api::V1::Demo::UserRepresenter,
             class: Demo::Mash,
             readable: true,
             writeable: true,
             schema_info: { required: true }

  collection :periods,
             extend: Api::V1::Demo::Course::PeriodRepresenter,
             class: Demo::Mash,
             readable: true,
             writeable: true,
             schema_info: { required: true }
end
