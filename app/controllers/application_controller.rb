class ApplicationController < ActionController::Base

  respond_to :html, :js

  include Lev::HandleWith

  before_filter :authenticate_user!

  fine_print_require :general_terms_of_use, :privacy_policy

end
