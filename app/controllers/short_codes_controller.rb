class ShortCodesController < ApplicationController
  skip_before_filter :authenticate_user!

  def redirect
    handle_with(ShortCode::ShortCodeRedirect,
                success: -> (*) { redirect_to @handler_result.outputs.uri },
                failure: -> (*) { render text: 'Short code not found', status: 404 })
  end
end
