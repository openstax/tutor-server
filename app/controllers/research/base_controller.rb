class Research::BaseController < ApplicationController
  before_action :authenticate_researcher!

  layout 'research'

  protected

  def authenticate_researcher!
    raise SecurityTransgression unless current_user.is_researcher?
  end
end
