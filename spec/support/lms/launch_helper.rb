class Lms::LaunchHelper
  def initialize(spec)
    @spec = spec
    @users = {}
  end

  def identify_user(identifier, user)
    @users[identifier] = user
  end

  def get_user(identifier)
    @users[identifier]
  end

  def get_user!(identifier, default: nil)
    get_user(identifier) || begin
      user = default || FactoryBot.create(:user_profile)
      identify_user(identifier, user)
    end
  end

  def pair_launch_to_course
    spec.instance_exec do
      expect(response.status).to eq 302

      get response.body.match(/a href=\"(.*)\"/)[1] # 'click' you are being redirected
      expect(response.body).to match 'pair'
    end
  end

  def complete_the_launch_locally(log_in_as: nil)
    spec.skip 'This spec requires signed params, which are disabled'

    # Within Tutor the launch bounces around a bit, off to Accounts and back
    # simulate that here.
    #
    # When the user is not yet known, can use the `log_in_as` user (simulates
    # a launched user saying "I already have an account" and logging in as that
    # user

    this = self

    spec.instance_exec do
      expect(response.status).to eq 200

      get response.body.match(/a target=\"_blank\" .* href=\"(.*)\"/)[1] # 'click' open in new tab

      expect(redirect_path).to eq "/accounts/login"
      expect(redirect_query_hash[:sp]).to be_blank
      expect(redirect_query_hash[:sp]["signature"]).not_to be_blank

      user_identifer = redirect_query_hash[:sp]["uuid"].split('--')[0]
      user = this.get_user!(user_identifer, default: log_in_as)

      stub_current_user(user)
      get redirect_query_hash[:return_to]

      user
    end
  end

  protected

  attr_reader :spec
end
