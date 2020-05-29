# Creates the admin, content, support, researchers, teachers, students and zz demo users
class Demo::Users < Demo::Base
  MAX_RETRIES = 3

  lev_routine transaction: :read_committed, use_jobba: true

  uses_routine User::SetAdministratorState, as: :set_administrator
  uses_routine User::SetContentAnalystState, as: :set_content_analyst
  uses_routine User::SetCustomerSupportState, as: :set_customer_support
  uses_routine User::SetResearcherState, as: :set_researcher

  protected

  def sign_contract(user:, name:)
    string_name = name.to_s
    return unless FinePrint::Contract.where(name: string_name).exists?

    FinePrint.sign_contract(user, string_name)
  end

  def create_or_update_users(users, type, attributes = {})
    outputs.users ||= []

    users_of_type = users[type]
    return outputs.public_send("#{type}=", []) if users_of_type.blank?

    usernames = users_of_type.map { |user| user[:username] }

    # Retries could be replaced with UPSERTing the users
    @retries = 0
    user_models = begin
      User::Models::Profile.transaction(requires_new: true) do
        existing_users_by_username = User::Models::Profile
          .joins(:account)
          .where(account: { username: usernames })
          .preload(:account)
          .index_by(&:username)

        users_of_type.map do |user|
          model = existing_users_by_username[user[:username]]
          attrs = attributes.merge(user)

          if model.nil?
            attrs[:password] ||= Rails.application.secrets.demo_user_password

            if attrs[:first_name].blank? && attrs[:last_name].blank?
              attrs[:full_name] ||= attrs[:username].split('_').map(&:capitalize).join(' ')

              attrs[:first_name], attrs[:last_name] = attrs[:full_name].split(' ', 2)
            else
              separator = attrs[:first_name].blank? || attrs[:last_name].blank? ? '' : ' '
              attrs[:full_name] ||= "#{attrs[:first_name]}#{separator}#{attrs[:last_name]}"
            end

            attrs[:is_test] = true if attrs[:is_test].nil?

            sign_contracts = attrs.has_key?(:sign_contracts) ? attrs[:sign_contracts] : true

            # The password will be set if stubbing is disabled
            model = run(
              User::FindOrCreateUser, attrs.except(:sign_contracts)
            ).outputs.user.tap do |user|
              next unless sign_contracts

              sign_contract(user: user, name: :general_terms_of_use)
              sign_contract(user: user, name: :privacy_policy)
            end
          else
            account_attrs = attrs.except :sign_contracts

            begin
              model.account.update_attributes account_attrs
            rescue OAuth2::Error
              # Don't care if we can't send the updates to Accounts
              model.account.update_columns account_attrs
            end
          end

          model
        end
      end
    rescue ActiveRecord::RecordNotUnique, PG::UniqueViolation
      # Retry race conditions due to multiple jobs trying to create the same user
      raise if @retries >= MAX_RETRIES

      @retries += 1

      retry
    end

    outputs.users += user_models
    outputs.public_send "#{type}=", user_models
  end

  def exec(users:)
    create_or_update_users(users, :administrators, role: :other).each do |user|
      run(:set_administrator, user: user, administrator: true)
      log { "Admin: #{user.username}" }
    end

    create_or_update_users(users, :content_analysts, role: :other).each do |user|
      run(:set_content_analyst, user: user, content_analyst: true)
      log { "Content Analyst: #{user.username}" }
    end

    create_or_update_users(users, :customer_support, role: :other).each do |user|
      run(:set_customer_support, user: user, customer_support: true)
      log { "Customer Support: #{user.username}" }
    end

    create_or_update_users(users, :researchers, role: :other).each do |user|
      run(:set_researcher, user: user, researcher: true)
      log { "Researcher: #{user.username}" }
    end

    create_or_update_users(
      users,
      :students,
      role: :student,
      school_type: :college,
      school_location: :domestic_school,
      is_kip: true
    ).each { |user| log { "Student: #{user.username}" } }

    create_or_update_users(
      users,
      :teachers,
      faculty_status: :confirmed_faculty,
      role: :instructor,
      school_type: :college,
      school_location: :domestic_school,
      is_kip: true
    ).each { |user| log { "Teacher: #{user.username}" } }

    log_status
  end
end
