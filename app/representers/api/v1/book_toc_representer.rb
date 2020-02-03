module Api::V1
  class BookTocRepresenter < BookPartTocRepresenter
    property :id,
             type: String,
             writeable: false,
             readable: true,
             schema_info: { required: true }

    property :archive_url,
             type: String,
             writeable: false,
             readable: true,
             schema_info: {
               required: false,
               description: "The base of the archive URL, e.g. 'https://archive.cnx.org'"
             }

    property :webview_url,
             type: String,
             writeable: false,
             readable: true,
             schema_info: {
               required: false,
               description: "The base of the webview URL, e.g. 'https://cnx.org'"
             }

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
