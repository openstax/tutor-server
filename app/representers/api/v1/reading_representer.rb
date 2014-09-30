module Api::V1
  class ReadingRepresenter < DetailedTaskRepresenter
    include Roar::Representer::JSON

    property :resource,
             class: Resource,
             decorator: ResourceRepresenter,
             writeable: false,
             schema_info: {
               required: true,
               description: "The Resource content/URL for this Reading"
             }             
                          
  end
end
