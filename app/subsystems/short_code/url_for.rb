class ShortCode::UrlFor
  lev_routine express_output: :url
  uses_routine ::ShortCode::FindShortCode,
               as: :find_short_code

  protected

  def exec(model, suffix: nil)
    code = run(:find_short_code, model.to_global_id.to_s).outputs.short_code
    if code
      outputs.url = Rails.application.routes.url_helpers.short_code_path(
                      short_code: code,
                      human_readable: suffix.try(:parameterize)
                    )
    end
  end
end
