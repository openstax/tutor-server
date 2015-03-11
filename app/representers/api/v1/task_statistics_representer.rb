module Api::V1

  class TaskStatisticsRepresenter < Roar::Decorator

    include Roar::Representer::JSON

    property :course,
      type: Object,
      readable: true,
      writeable: false,
      decorator: TaskPeriodStatisticsRepresenter

    collection :periods,
      readable: true,
      writable: false,
      decorator: TaskPeriodStatisticsRepresenter

  end
end
