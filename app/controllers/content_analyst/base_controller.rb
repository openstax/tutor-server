class ContentAnalyst::BaseController < ApplicationController
  before_action :authenticate_content_analyst!

  layout 'content_analyst'

  protected

  def authenticate_content_analyst!
    raise SecurityTransgression unless current_user.is_content_analyst? || current_user.is_admin?
  end
end
