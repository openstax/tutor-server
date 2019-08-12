class CustomerService::BaseController < ApplicationController
  before_action :authenticate_customer_service!

  layout 'customer_service'

  protected

  def authenticate_customer_service!
    raise SecurityTransgression unless current_user.is_customer_support? || current_user.is_admin?
  end
end
