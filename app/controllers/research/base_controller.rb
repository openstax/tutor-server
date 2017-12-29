class Research::BaseController < ApplicationController
  before_filter :authenticate_admin_or_researcher!

  layout 'research'

  protected

  def authenticate_admin_or_researcher!
    raise SecurityTransgression unless current_user.is_admin? || current_user.is_researcher?
  end
end
