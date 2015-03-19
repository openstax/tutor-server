module Api::V1
  class TaskedVideoRepresenter < TaskedReadingRepresenter

    property :video_url,
             type: String,
             writeable: false,
             readable: true,
             schema_info: {
               required: false,
               description: "The video URL"
             }
  end
end
