class Api::V1::Research::BaseController < Api::V1::ApiController
  before_action :authenticate_researcher!

  protected

  def authenticate_researcher!
    raise SecurityTransgression if current_human_user.nil? || !current_human_user.is_researcher?
  end
end
