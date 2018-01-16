module Api::V1::PerformanceReport
  class Representer < Roar::Decorator
    include Representable::JSON::Collection

    items extend: PeriodRepresenter
  end
end
