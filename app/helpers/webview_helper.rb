module WebviewHelper
  def homepage_background_pack_path(image)
    return unless image
    asset_pack_path("media/images/homepage/#{image}")
  end

  def homepage_background_style(image)
    return unless image
    "background-image: url(#{homepage_background_pack_path(image)})"
  end
end
