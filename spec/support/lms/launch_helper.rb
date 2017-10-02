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
      user = default || FactoryGirl.create(:user)
      identify_user(identifier, user)
    end
  end

  def complete_the_launch_locally(log_in_as: nil)
    # Within Tutor the launch bounces around a bit, off to Accounts and back
    # simulate that here.
    #
    # When the user is not yet known, can use the `log_in_as` user (simulates
    # a launched user saying "I already have an account" and logging in as that
    # user

    this = self

    spec.instance_eval do
      expect(response.status).to eq 200

      get response.body.match(/href=\"(.*)\"/)[1] # 'click' open in new tab

      expect(redirect_path).to eq "/accounts/login"
      expect(redirect_query_hash[:sp]["signature"]).not_to be_blank

      user_identifer = redirect_query_hash[:sp]["uuid"]
      user = this.get_user!(user_identifer, default: log_in_as)

      stub_current_user(user)
      get redirect_query_hash[:return_to]

      user
    end
  end

  protected

  attr_reader :spec

end
