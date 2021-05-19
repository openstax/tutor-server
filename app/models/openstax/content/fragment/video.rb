require_relative '../fragment'

class OpenStax::Content::Fragment::Video < OpenStax::Content::Fragment::Embedded
  self.default_width = 560
  self.default_height = 315
  self.iframe_classes += ['video']
  self.iframe_title = "Video"
end
