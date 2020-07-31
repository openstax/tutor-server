class Admin::UsersController < Admin::BaseController
  include Manager::SearchUsers

  before_action :get_user, only: [ :edit, :update, :become ]

  def create
    handle_with(
      Admin::UsersCreate,
      success: ->(*) {
        flash[:notice] = 'The user has been added.'
        redirect_to admin_users_path(
          search_term: @handler_result.outputs.user.username
        )
      },
      failure: ->(*) {
        flash[:error] = 'Invalid user information: ' + @handler_result.errors.first.message
        redirect_to new_admin_user_path
      }
    )
  end

  def edit
  end

  def update
    handle_with(
      Admin::UsersUpdate,
      user: @user,
      success: ->(*) {
        flash[:notice] = 'The user has been updated.'
        redirect_to admin_users_path(
          search_term: @handler_result.outputs.user.username
        )
      },
      failure: ->(*) {
        flash[:error] = 'Invalid user information.'
        redirect_to new_admin_user_path
      }
    )
  end

  def become
    session[:admin_user_id] = current_user.id
    sign_in(@user.account)
    redirect_to root_path
  end

  def info
  end

  private

  def get_user
    @user = User::Models::Profile.find(params[:id])
  end
end
