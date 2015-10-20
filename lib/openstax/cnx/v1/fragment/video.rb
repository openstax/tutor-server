module OpenStax::Cnx::V1::Fragment
  class Video < Embedded
    include ActsAsFragment

    self.default_width = 560
    self.default_height = 315
  end
end
