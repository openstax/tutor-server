module Api::V1
  class DetailedTaskRepresenter < Roar::Decorator
    include Roar::Representer::JSON

    property :id, 
             writeable: false

    # def self.sub_representer_for(detailed_task)
    #   case detailed_task.format
    #   when Reading 
    #     Api::V1::ReadingRepresenter
    #   end
    # end

    # def self.sub_model_for(hsh) 
    #   case hash[:type]
    #   when 'reading'
    #     Reading
    #   end
    # end

    class SubModelFinder
      include Uber::Callable
 
      def call(*args)
        case args[0][:type]
        when 'reading'
          Reading
        end
      end
    end

    class SubRepresenterFinder
      include Uber::Callable
 
      def call(*args)
        if args[0] == :all_sub_representers
          [Api::V1::ReadingRepresenter]
        else
          case args[0].class
          when Reading 
            Api::V1::ReadingRepresenter
          end
        end
      end
    end

  end
end

