class Admin::BaseController < ActionController::Base
  before_filter :authenticate_admin!

  def authenticate_admin!
    raise SecurityTransgression unless current_user.administrator
  end
end