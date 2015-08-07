class ApplicationController < ActionController::Base

  respond_to :html, :js

  include Lev::HandleWith

  before_filter :authenticate_user!

end
