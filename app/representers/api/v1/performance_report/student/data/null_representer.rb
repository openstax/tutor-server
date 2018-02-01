module Api::V1::PerformanceReport::Student::Data
  class NullRepresenter < Roar::Decorator
    include Roar::JSON

    def to_hash(*args)
      nil
    end

    def to_json(*args)
      'null'
    end
  end
end
