class Admin::TestsController < Admin::BaseController

  # A place to test things, e.g. page layouts

  layout 'minimal_error', only: :minimal_error

  def minimal_error; end

  def minimal_error_iframe; end


end
