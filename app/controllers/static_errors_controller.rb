class StaticErrorsController < ApplicationController
  respond_to :html

  skip_before_action :authenticate_user!

  layout 'static_error'

  [ 400, 422, 500, 503 ].each { |error_code| define_method(error_code.to_s) { @code = error_code } }
end
