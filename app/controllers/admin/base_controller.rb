class Admin::BaseController < ApplicationController
  CUSTOMER_SERVICE_ACTIONS = ['index', 'show']

  before_filter :authenticate_admin!

  layout 'admin'

  def authenticate_admin!
    raise SecurityTransgression unless current_user.is_admin? || \
                                       (current_user.is_customer_service? && \
                                        CUSTOMER_SERVICE_ACTIONS.include?(action_name))
  end
end
