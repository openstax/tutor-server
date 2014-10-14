module Api::V1
  class TaskRepresenterMapper
    include Uber::Callable

    def self.models 
      map.keys
    end

    def self.representers
      map.values.collect{|v| v.call}
    end

    def call(*args)
      if args[2].is_a?(Hash) && args[2][:all_sub_representers]
        self.class.representers
      else
        klass = args[1].is_a?(Class) ? args[1] : args[1].class
        self.class.map[klass]
      end
    end

protected

    def self.map
      @@map ||= {
        Reading => ->(*) {Api::V1::ReadingRepresenter},
        Interactive => ->(*) {Api::V1::InteractiveRepresenter}
      }
    end

  end
end
