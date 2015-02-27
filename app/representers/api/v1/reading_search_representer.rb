module Api::V1
  class ReadingSearchRepresenter

    collection :items, decorator:

    collection :items, inherit: true,
                       class: Task,
                       decorator: TaskRepresenter

  end
end
