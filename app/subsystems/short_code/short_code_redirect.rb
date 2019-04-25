class ShortCode::ShortCodeRedirect
  lev_handler

  uses_routine ShortCode::GetShortCodeUrl, translations: { outputs: { type: :verbatim } }

  protected

  def authorized?
    true
  end

  def handle
    run(:short_code_get_short_code_url, short_code: params[:short_code],
        user: caller, role: options[:role])
  end
end
