class ShortCode::GetShortCodeUrl
  lev_routine

  uses_routine Tasks::GetRedirectUrl, translations: { outputs: { type: :verbatim } }

  protected
  def exec(short_code:, user:, role:)
    short_code = ShortCode::Models::ShortCode.find_by_code(short_code)
    fatal_error(code: :short_code_not_found) if short_code.nil?

    if short_code.uri.starts_with?('gid://')
      # GIDs
      if short_code.uri.starts_with?('gid://tutor/Tasks::Models::TaskPlan')
        run(:tasks_get_redirect_url, gid: short_code.uri, user: user, role: role)
      else
        fatal_error(code: :no_handler_for_gid)
      end
    else
      outputs[:uri] = short_code.uri
    end
  end
end
