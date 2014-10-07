module Api::V1
  class TaskRepresenterMapper
    include Uber::Callable

    def self.map
      @@map ||= {
        Reading => Api::V1::ReadingRepresenter
      }
    end

    def self.models 
      map.keys
    end

    def self.representers
      map.values
    end

    def call(*args)
      if args[0] == :all_sub_representers
        self.class.representers
      else
        self.class.map[args[1].class]
      end
    end
  end
end