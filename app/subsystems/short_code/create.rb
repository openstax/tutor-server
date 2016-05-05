class ShortCode::Create
  lev_routine express_output: :short_code

  protected

  def exec(uri)
    short_code = ShortCode::Models::ShortCode.create(uri: uri)
    outputs.short_code = short_code.code
    transfer_errors_from(short_code, type: :verbatim)
  end
end
