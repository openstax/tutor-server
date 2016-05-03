class ShortCodesController < ApplicationController
  skip_before_filter :authenticate_user!

  def redirect
    handle_with(ShortCode::ShortCodeRedirect,
                success: -> (*) { redirect_to @handler_result.outputs.uri },
                failure: -> (*) { raise ShortCodeNotFound })
  end
end

class ShortCodeNotFound < StandardError; end
