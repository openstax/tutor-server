class Admin::UsersController < Admin::BaseController
  before_action :get_user_and_roles, only: [:edit, :update]

  def index
    @users = GetAllUserProfiles[]
  end

  def create
    handle_with(Admin::UsersCreate,
                complete: -> (*) {
                  add_roles(@handler_result.outputs[:profile].entity_user)
                  update_account(@handler_result.outputs[:profile], [:full_name])
                  flash[:notice] = 'The user has been added.'
                  redirect_to admin_users_path
                })
  end

  def edit
  end

  def update
    add_roles(@user.entity_user)
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
  def get_user_and_roles
    @user = UserProfile::Models::Profile.find(params[:id])
    @roles = Role::GetUserRoles.call(@user.entity_user).outputs[:roles]
    @roles = @roles.collect { |r| r.role_type }.uniq
  end

  def add_roles(user)
    Role::CreateUserRole[user, :teacher] unless params[:roles_teacher].nil? || @roles.include?('teacher')
    Role::CreateUserRole[user, :student] unless params[:roles_student].nil? || @roles.include?('student')
  end

  def update_account(profile, fields)
    attributes = {}
    fields.each do |field|
      attributes[field] = params[:user][field] if params[:user][field].present?
    end

    profile.account.update_attributes(attributes) if attributes.present?
  end
end
