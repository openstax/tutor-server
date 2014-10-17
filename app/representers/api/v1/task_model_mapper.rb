module Api::V1
  class TaskModelMapper
    include Uber::Callable

    def call(context, fragment, *args)
      fragment['type'].classify.constantize
    end
  end
end
