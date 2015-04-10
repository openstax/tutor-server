module Api::V1

  class IReadingStatsRepresenter < Roar::Decorator

    include Roar::JSON

    property :course,
      type: Object,
      readable: true,
      writeable: false,
      decorator: IReadingPeriodStatsRepresenter

    collection :periods,
      readable: true,
      writable: false,
      decorator: IReadingPeriodStatsRepresenter

  end
end
