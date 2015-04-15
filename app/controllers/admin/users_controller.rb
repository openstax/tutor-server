class Admin::UsersController < Admin::BaseController
  def index
    @users = GetAllUserProfiles[]
  end

  def create
    handle_with(Admin::UsersCreate,
                complete: -> (*) {
                  flash[:notice] = 'The user has been added.'
                  redirect_to admin_users_path
                })
  end

  def become
    account = GetAccount[params[:id]]
    sign_in(account)
    redirect_to root_path
  end
end
