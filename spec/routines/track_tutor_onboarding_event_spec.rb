require 'rails_helper'

RSpec.describe TrackTutorOnboardingEvent, type: :routine, vcr: VCR_OPTS do

  before(:all) do
    VCR.use_cassette('TrackTutorOnboardingEvent/sf_setup', VCR_OPTS) do
      @proxy = SalesforceProxy.new
      load_salesforce_user
      @proxy.ensure_schools_exist(["JP University"])
      @sf_contact_a = @proxy.new_contact

      # Note: In order to create campaigns, the SF user being used for this test must have
      # the 'Marketing User' permission, which system admins do not have by default.

      @campaign = @proxy.new_campaign
      @nomad_campaign = @proxy.new_campaign
    end

    # To use placeholders for the user UUIDs, we have to set them up in a before(:all)
    # call, because `define_cassette_placeholder` doesn't work well from a before(:each)

    @user_no_sf = FactoryBot.create(:user, is_test: false)
    @user_sf_a = FactoryBot.create(:user, is_test: false, salesforce_contact_id: @sf_contact_a.id)

    VCR.configure do |config|
      config.define_cassette_placeholder("<USER_NO_SF_UUID>") { @user_no_sf.uuid }
      config.define_cassette_placeholder("<USER_SF_A_UUID>")  { @user_sf_a.uuid  }
    end
  end

  # We are reusing one SF contact and the two users so that we can correctly
  # put placeholders in for the user's UUIDs.  But each spec expects that
  # no CMs (CampaignMembers) have been created for the SF contact yet, so track
  # which CMs we create and destroy them after each spec.

  before(:each) do
    @delete_me = []

    allow_any_instance_of(OpenStax::Salesforce::Remote::CampaignMember).to receive(:create!).and_wrap_original do |m, *args|
      m.call(*args).tap{|object| @delete_me.push(object)}
    end
  end

  after(:each) do
    @delete_me.each{|obj| obj.destroy}
  end

  let(:anonymous_user) do
    profile = User::Models::AnonymousProfile.instance
    strategy = User::Strategies::Direct::AnonymousUser.new(profile)
    User::User.new(strategy: strategy)
  end

  let(:data) { {} }

  def call
    described_class[user: user, event: event, data: data].try(:reload)
  end

  def expect_call_to_set_timestamp(timestamp_field)
    cm = nil
    time = Chronic.parse("July 23, 2017 5:04pm")
    Timecop.freeze(time) do
      cm = call
      expect(cm).to be_persisted
      expect(cm.send(timestamp_field)).to be_within(1.second).of(DateTime.parse(time.to_s))
    end
    cm
  end

  def expect_2nd_call_to_not_change_timestamp(timestamp_field)
    cm = call
    first_time = cm.send(timestamp_field)
    Timecop.freeze(5.minutes.from_now) do
      cm = call
      expect(cm.send(timestamp_field)).to be_within(1.seconds).of(first_time)
    end
  end

  def expect_2nd_call_to_change_timestamp(timestamp_field)
    cm = call
    first_time = cm.send(timestamp_field)
    Timecop.freeze(5.minutes.from_now) do
      cm = call
      expect(cm.send(timestamp_field)).to be_within(1.seconds).of(first_time + 5.minutes)
    end
  end

  def stub_active_campaign_id(value = nil)
    allow(Settings::Salesforce).to receive(:active_onboarding_salesforce_campaign_id) {
      value || @campaign.id
    }
  end

  def stub_active_nomad_campaign_id(value = nil)
    allow(Settings::Salesforce).to receive(:active_nomad_onboarding_salesforce_campaign_id) {
      value || @nomad_campaign.id
    }
  end

  context "when the user is a test user" do
    let(:event) { :booyah }
    let(:user)  { FactoryBot.create :user, is_test: true }

    it "does not error for any reason" do
      stub_active_campaign_id(" ")
      stub_active_nomad_campaign_id(" ")
      clear_salesforce_user
      ActiveForce.clear_sfdc_client!
      expect{ call }.not_to raise_error
    end
  end

  context "when there is no SF user" do
    let(:event) { :like_preview_yes }
    let(:user) { @user_sf_a }

    it "freaks out in production" do
      stub_active_campaign_id
      clear_salesforce_user
      ActiveForce.clear_sfdc_client!
      expect{call}.to raise_error(OpenStax::Salesforce::UserMissing)
    end
  end

  context 'when user anonymous' do
    let(:event) { :created_preview_course }
    let(:user) { anonymous_user } # this combo can't really happen, but just tests code

    it 'raises an error' do
      expect{call}.to raise_error(TrackTutorOnboardingEvent::CannotTrackOnboardingUser)
    end
  end

  context 'when user has no SF contact ID' do

    let(:user) { @user_no_sf }

    context 'arrived my courses' do
      let(:event) { :arrived_my_courses }

      it 'does nothing' do
        expect{call}.not_to raise_error
      end
    end

    context 'other' do
      let(:event) { :created_preview_course }

      it 'raises an error' do
        expect{call}.to raise_error(TrackTutorOnboardingEvent::CannotTrackOnboardingUser)
      end
    end

  end

  context 'when user has an SF contact ID' do
    let(:event) { :arrived_my_courses }
    let(:user) { @user_sf_a }

    it 'errors when the active campaign ID is not set' do
      stub_active_campaign_id(" ")
      expect{call}.to raise_error(TrackTutorOnboardingEvent::MissingOnboardingCampaignId, /active/)
    end
  end

  context 'when campaign member exists' do
    before(:each) {
      @campaign_member = @proxy.new_campaign_member(
                           contact_id: @user_sf_a.salesforce_contact_id,
                           campaign_id: @campaign.id
                          )

      stub_active_campaign_id
    }

    context 'arrived my courses' do
      let(:event) { :arrived_my_courses }
      let(:user) { @user_sf_a }

      it 'sets first_arrived_my_courses_at' do
        expect_call_to_set_timestamp(:first_arrived_my_courses_at)
      end

      it 'does not change first_arrived_my_courses_at for 2nd time' do
        expect_2nd_call_to_not_change_timestamp(:first_arrived_my_courses_at)
      end
    end

    context 'created preview' do
      let(:event) { :created_preview_course }
      let(:user) { @user_sf_a }

      it 'sets preview_created_at' do
        expect_call_to_set_timestamp(:preview_created_at)
      end

      it 'does not change preview_created_at for 2nd time' do
        expect_2nd_call_to_not_change_timestamp(:preview_created_at)
      end
    end

    context 'created real course' do
      let(:event) { :created_real_course }
      let(:user) { @user_sf_a }
      let(:course) { FactoryBot.create :course_profile_course }
      let(:data) { {course_id: course.id} }

      it 'sets real_course_created_at' do
        expect_call_to_set_timestamp(:real_course_created_at)
      end

      it 'sets the campaign member ID on the course' do
        cm = call
        expect(cm.id).to_not eq nil
        expect(course.reload.creator_campaign_member_id).to eq cm.id
      end

      it 'does not change real_course_created_at for 2nd time' do
        expect_2nd_call_to_not_change_timestamp(:real_course_created_at)
      end
    end

    context 'ask later about like preview' do
      let(:event) { :like_preview_ask_later }
      let(:user) { @user_sf_a }

      it 'updates the count' do
        cm = call
        expect(cm.like_preview_ask_later_count).to eq 1

        cm = call
        expect(cm.like_preview_ask_later_count).to eq 2
      end
    end

    context 'say yes to like preview' do
      let(:event) { :like_preview_yes }
      let(:user) { @user_sf_a }

      it 'sets like_preview_yes' do
        expect_call_to_set_timestamp(:like_preview_yes_at)
      end

      it 'does not change like_preview_yes for 2nd preview' do
        expect_2nd_call_to_not_change_timestamp(:like_preview_yes_at)
      end
    end

    context 'adoption decision' do
      let(:event) { :made_adoption_decision }
      let(:user) { @user_sf_a }
      let(:course) { FactoryBot.create :course_profile_course }
      let(:data) {{
        decision: "For course credit",
        course_id: course.id
      }}

      it "errors if data missing" do
        data[:decision] = ""
        expect{call}.to raise_error(TrackTutorOnboardingEvent::MissingArgument)
      end

      it 'saves the timestamp' do
        expect_call_to_set_timestamp(:latest_adoption_decision_at)
      end

      it 'saves the decision' do
        cm = call
        expect(cm.latest_adoption_decision).to eq "For course credit"
        expect(course.reload.latest_adoption_decision).to eq "For course credit"
      end

      it 'overwrites the first timestamp if done again' do
        expect_2nd_call_to_change_timestamp(:latest_adoption_decision_at)
      end

      it 'overwrites the first decision if done again' do
        cm = call
        data[:decision] = "For extra credit"
        cm = call
        expect(cm.latest_adoption_decision).to eq "For extra credit"
      end
    end

    context "when event unknown" do
      let(:event) { :booyah }
      let(:user) { @user_sf_a }

      it 'raise an exception' do
        expect{call}.to raise_error(StandardError)
      end
    end

  end

  context 'when campaign member does not exist' do
    before { stub_active_campaign_id }

    context 'say yes to like preview (arbitrary event to test nomad context)' do
      let(:event) { :like_preview_yes }
      let(:user) { @user_sf_a }

      context "when the nomad campaign ID is set" do
        before { stub_active_nomad_campaign_id }

        it 'tracks on a new campaign member on the nomad campaign' do
          cm = expect_call_to_set_timestamp(:like_preview_yes_at)
          expect(cm.campaign_id).to eq @nomad_campaign.id
        end

        it 'tracks on a new campaign member on the nomad campaign and then reuses that next time' do
          cm = expect_call_to_set_timestamp(:like_preview_yes_at)
          expect(cm.campaign_id).to eq @nomad_campaign.id

          course = FactoryBot.create(:course_profile_course)
          cm2 = described_class[user: user,
                                event: :made_adoption_decision,
                                data: {decision: "For extra credit",
                                       course_id: course.id}].reload
          expect(cm2.id).to eq cm.id
        end
      end

      context "when the nomad campaign ID is NOT set" do
        before { stub_active_nomad_campaign_id(" ") }

        it 'errors when the active campaign ID is not set' do
          expect{call}.to raise_error(TrackTutorOnboardingEvent::MissingOnboardingCampaignId, /nomad/)
        end
      end
    end
  end

  context 'when run in background' do
    def expect_instant_background_failure(exception_class, &block)
      Delayed::Worker.with_delay_jobs(true) do
        expect_any_instance_of(exception_class).to receive(
          :instantly_fail_if_in_background_job?
        ).and_call_original
        expect_any_instance_of(Delayed::Job).to receive(:fail!).and_call_original
        block.call
        expect(Delayed::Worker.new.work_off).to eq [0,1]
      end
    end

    it 'fails instantly for an unknown event' do
      expect_instant_background_failure(TrackTutorOnboardingEvent::InstantFailStandardError) {
        described_class.perform_later(user: "whatever", event: "wowzer")
      }
    end

    it 'fails instantly for missing arguments' do
      expect_instant_background_failure(TrackTutorOnboardingEvent::MissingArgument) {
        described_class.perform_later(user: "whatever", event: "made_adoption_decision")
      }
    end

    it 'fails instantly when cannot get CM' do
      expect_instant_background_failure(TrackTutorOnboardingEvent::CannotTrackOnboardingUser) {
        described_class.perform_later(user: anonymous_user, event: "created_preview_course")
      }
    end

    it 'retries if there are SF errors on save' do
      stub_active_campaign_id
      stub_active_nomad_campaign_id

      Delayed::Worker.with_delay_jobs(true) do
        # Stub the `errors` call in the track routine to return true so we simulate a SF error
        errors_call_count = 0
        allow_any_instance_of(
          OpenStax::Salesforce::Remote::CampaignMember
        ).to receive(:errors).and_wrap_original { |m, *args|
          errors_call_count += 1
          3 == errors_call_count ? ["blah"] : m.call(*args)
        }

        described_class.perform_later(user: @user_sf_a, event: "like_preview_yes")

        expect_any_instance_of(Delayed::Job).not_to receive(:fail!)
        s,f = Delayed::Worker.new.work_off(1)
        expect(Delayed::Job.first.attempts).to eq 1
        expect(Delayed::Job.first.failed_at).to be_nil
      end
    end

  end


end
