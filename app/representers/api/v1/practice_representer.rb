module Api::V1
  class PracticeRepresenter < Roar::Decorator

    include Roar::JSON

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
