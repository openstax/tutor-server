class Admin::BaseController < ApplicationController
  CUSTOMER_SUPPORT_ACTIONS = ['index', 'show']

  before_filter :authenticate_admin!

  layout 'admin'

  def authenticate_admin!
    raise SecurityTransgression unless current_user.is_admin? || \
                                       (current_user.is_customer_support? && \
                                        CUSTOMER_SUPPORT_ACTIONS.include?(action_name))
  end
end
