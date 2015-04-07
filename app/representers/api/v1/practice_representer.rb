module Api::V1
  class PracticeRepresenter < Roar::Decorator

    include Roar::JSON

    collection :page_ids,
               writeable: true,
               readable: true,
               schema_info: {
                 description: "The page_ids to use for practice",
                 items: {
                   type: 'integer'
                 }
               }

    collection :book_part_ids,
               writeable: true,
               readable: true,
               schema_info: {
                 description: "The book_part_ids to use for practice",
                 items: {
                   type: 'integer'
                 }
               }

  end
end
