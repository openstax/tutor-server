class Admin::BaseController < ApplicationController
  before_action :authenticate_admin!

  content_security_policy do |policy|
    policy.script_src :self, :https, :unsafe_inline, :unsafe_eval
  end

  layout 'admin'

  protected

  def authenticate_admin!
    raise SecurityTransgression unless current_user.is_admin?
  end
end
