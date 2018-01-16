module Api::V1::PerformanceReport
  class Representer < Roar::Decorator
    include Representable::JSON::Collection

    items extend: ::Api::V1::PerformanceReport::PeriodRepresenter
  end
end
