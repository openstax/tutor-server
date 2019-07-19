class Api::V1::Demo::Work::TaskRepresenter < Roar::Decorator
  include Representable::JSON::Hash
  include Representable::Hash::AllowSymbols
  include Representable::Coercion

  property :student,
           decorator: Api::V1::Demo::UserRepresenter,
           readable: true,
           writeable: true,
           schema_info: { required: true }

  # Progress and correct are numbers from 0 to 1, inclusive
  # Progress is the fraction of completed steps
  # Rounded to the nearest whole number of steps
  property :progress,
           type: Float,
           readable: true,
           writeable: true,
           schema_info: { required: true }

  # Score is the chance of each step being correct (so there's some deviation)
  # Required unless progress is 0
  property :score,
           type: Float,
           readable: true,
           writeable: true

  # In seconds, 0 is exactly at the due date, default is -300
  # If 0 is specified, then Timecop.freeze is used
  # Otherwise, Timecop.travel is used
  property :lateness,
           type: Integer,
           readable: true,
           writeable: true
end
