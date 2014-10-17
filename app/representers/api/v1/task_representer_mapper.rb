module Api::V1
  class TaskRepresenterMapper
    include Uber::Callable

    def self.models 
      map.keys
    end

    def self.representers
      map.values
    end

    def call(context, ioc, *args)
      if args[0].is_a?(Hash) && args[0][:all_sub_representers]
        self.class.representers
      else
        klass = ioc.is_a?(Class) ? ioc : \
                  (ioc.is_a?(Task) ? \
                    ioc.details_type.classify.constantize : \
                    ioc.class)
        self.class.map[klass]
      end
    end

protected

    def self.map
      @@map ||= {
        Reading => Api::V1::ReadingRepresenter,
        Interactive => Api::V1::InteractiveRepresenter
      }
    end

  end
end
