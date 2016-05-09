class ShortCode::UrlFor
  lev_routine express_output: :url
  uses_routine ::ShortCode::FindShortCode,
               as: :find_short_code

  protected

  def exec(model)
    code = run(:find_short_code, model.to_global_id.to_s).outputs.short_code
    if code
      title = model.try(:title)
      title_part = title ? "/#{title.parameterize}" : ''
      outputs.url = '/@' + code + title_part
    end
  end
end
