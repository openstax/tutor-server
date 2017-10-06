class Admin::TestsController < Admin::BaseController

  # A place to test things, e.g. page layouts

  layout 'minimal_error', only: :minimal_error

  def minimal_error; end

  def minimal_error_iframe; end

  def launch_iframe; end

  def launch
    render template: 'lms/launch', layout: false
  end

end
