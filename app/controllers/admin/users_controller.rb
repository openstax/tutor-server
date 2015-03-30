class Admin::UsersController < Admin::BaseController
  def index
    @users = Domain::ListUsers.call.outputs.users
  end

  def create
    handle_with(Admin::UsersCreate,
                complete: -> (*) {
                  flash[:notice] = 'The user has been added.'
                  redirect_to admin_users_path
                })
  end

  def become
    handle_with(Domain::GetAccount,
                complete: -> (*) {
                  sign_in(@handler_result.outputs[:account])
                  redirect_to root_path
                })
  end
end
