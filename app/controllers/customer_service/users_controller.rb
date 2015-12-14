class CustomerService::UsersController < CustomerService::BaseController
  def index
    @per_page = 30
    @user_search = User::SearchUsers.call(search: "%#{params[:query]}%",
                                          page: params[:page],
                                          per_page: @per_page)
  end
end
