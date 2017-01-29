class Admin::UsersController < Admin::BaseController
  before_action :get_user, only: [:edit, :update, :become]

  def index
    @per_page = 30
    @user_search = User::SearchUsers[search: "%#{params[:query]}%",
                                     page: params[:page],
                                     per_page: @per_page]

    respond_to do |format|
      format.html
      format.json { render json: Api::V1::Admin::UserSearchRepresenter.new(@user_search).to_json }
    end
  end

  def create
    handle_with(
      Admin::UsersCreate,
      success: ->(*) {
        flash[:notice] = 'The user has been added.'
        redirect_to admin_users_path(
          search_term: @handler_result.outputs[:user].username
        )
      },
      failure: ->(*) {
        flash[:error] = 'Invalid user information. ' +
                          @handler_result.errors.first.message
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
          search_term: @handler_result.outputs[:user].username
        )
      },
      failure: ->(*) {
        flash[:error] = 'Invalid user information.'
        redirect_to new_admin_user_path
      }
    )
  end

  def become
    sign_in(@user.account)
    redirect_to root_path
  end

  def info
  end

  private

  def get_user
    @user = User::User.find(params[:id])
  end
end
