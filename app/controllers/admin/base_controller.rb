class Admin::BaseController < ApplicationController
  before_action :authenticate_admin!

  layout 'admin'

  protected

  def authenticate_admin!
    raise SecurityTransgression unless current_user.is_admin?
  end
end
