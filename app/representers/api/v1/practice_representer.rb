module Api::V1
  class PracticeRepresenter < Roar::Decorator

    include Roar::JSON

    property :mode,
             type: String,
             writeable: true,
             readable: false,
             schema_info: {
               description: "The practice mode, either \"specific\" or \"most_needed\""
             }

    collection :page_ids,
               writeable: true,
               readable: false,
               schema_info: {
                 description: "The page ids to use for practice",
                 items: {
                   type: 'string'
                 }
               }

    collection :chapter_ids,
               as: :book_part_ids,
               writeable: true,
               readable: false,
               schema_info: {
                 description: "The chapter ids to use for practice",
                 items: {
                   type: 'string'
                 }
               }

  end
end
