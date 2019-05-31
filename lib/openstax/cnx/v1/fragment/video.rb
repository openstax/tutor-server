class OpenStax::Cnx::V1::Fragment
  class Video < Embedded
    self.default_width = 560
    self.default_height = 315
    self.iframe_classes += ['video']
    self.iframe_title = "Video"
  end
end
