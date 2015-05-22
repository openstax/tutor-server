class Admin::UsersController < Admin::BaseController
  before_action :get_user, only: [:edit, :update]

  def index
    @users = UserProfile::SearchProfiles[search_term: "%#{params[:search_term]}%"].paginate(page: params[:page], per_page: 30) if params[:search_term].present?
  end

  def create
    handle_with(Admin::UsersCreate,
                complete: -> (*) {
                  update_account(@handler_result.outputs[:profile], [:full_name])
                  flash[:notice] = 'The user has been added.'
                  redirect_to admin_users_path(search_term: @handler_result.outputs[:profile].username)
                })
  end

  def edit
  end

  def update
    update_account(@user, [:username, :full_name])
    flash[:notice] = 'The user has been updated.'
    redirect_to admin_users_path
  end

  def become
    account = GetAccount[params[:id]]
    sign_in(account)
    redirect_to root_path
  end

  private
  def get_user
    @user = UserProfile::Models::Profile.find(params[:id])
  end

  def update_account(profile, fields)
    attributes = {}
    fields.each do |field|
      attributes[field] = params[:user][field] if params[:user][field].present?
    end

    profile.account.update_attributes(attributes) if attributes.present?
  end
end
