module Api::V1
  class TaskModelMapper
    include Uber::Callable

    def call(*args)
      args[0]['type'].classify.constantize
    end
  end
end
