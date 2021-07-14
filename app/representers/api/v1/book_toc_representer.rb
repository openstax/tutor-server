# If you modify this representer, you must run `Content::Models::Ecosystem.find_each(&:touch)`
module Api::V1
  class BookTocRepresenter < BookPartTocRepresenter
    property :id,
             type: String,
             writeable: false,
             readable: true,
             schema_info: { required: true }

    property :baked_at,
             type: String,
             writeable: false,
             readable: true,
             schema_info: {
               required: false,
               description: "The date the book was baked.  Will be null if the book is not baked"
             }

    property :is_collated,
             writeable: false,
             readable: true,
             schema_info: {
               required: true,
               type: 'boolean',
               description: "If the book has been collated during processing."
             }
  end
end
