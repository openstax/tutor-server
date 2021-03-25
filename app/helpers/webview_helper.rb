module WebviewHelper
  def homepage_background_pack_path(image)
    return unless image
    path = "media/images/homepage/#{image}"
    "background-image: url(#{asset_pack_path(path)})"
  end
end
