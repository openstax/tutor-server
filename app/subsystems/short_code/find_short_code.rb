class ShortCode::FindShortCode
  lev_routine express_output: :short_code

  protected

  def exec(uri)
    outputs.short_code = ShortCode::Models::ShortCode.find_by_uri(uri).try(:code)
  end
end
