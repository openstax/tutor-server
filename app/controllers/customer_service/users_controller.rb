class CustomerService::UsersController < CustomerService::BaseController
  def index
    @per_page = 30
    @user_search = User::SearchUsers[search: "%#{params[:search_term]}%",
                                     page: params[:page],
                                     per_page: @per_page]

    respond_to do |format|
      format.html
      format.json { render json: Api::V1::Admin::UserSearchRepresenter.new(@user_search).to_json }
    end
  end
end
