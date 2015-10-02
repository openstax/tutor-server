class ApplicationController < ActionController::Base
  use_openstax_exception_rescue

  respond_to :html, :js

  include Lev::HandleWith

  before_filter :authenticate_user!

end
