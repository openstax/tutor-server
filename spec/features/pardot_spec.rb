require 'rails_helper'

RSpec.describe "Pardot" do
  # No real SF tests here, lots of those in tracking routine spec
  before(:each) { disable_sfdc_client }

  let(:user) { FactoryGirl.create :user }
  let(:anonymous_user) do
    profile = User::Models::AnonymousProfile.instance
    strategy = User::Strategies::Direct::AnonymousUser.new(profile)
    User::User.new(strategy: strategy)
  end

  def happy_path_test(expected_user)
    Delayed::Worker.with_delay_jobs(true) do
      visit '/pardot/toa?' + {sfc: "a", piaid: "b", picid: "c"}.to_query
      # signed in case goes to .../dashboard but side effect
      expect(current_url).to match redirect_url
      expect_any_instance_of(TrackTutorOnboardingEvent).to receive(:exec).with(
        event: "arrived_tutor_marketing_page_from_pardot",
        user: expected_user,
        data: {
          pardot_reported_contact_id: "a",
          pardot_reported_piaid: "b",
          pardot_reported_picid: "c"
        }
      )
      expect(Delayed::Worker.new.work_off).to eq [1,0]
    end
  end

  context "TutorOnboardingA arrivals" do
    scenario "explosion when redirect URL not set" do
      Delayed::Worker.with_delay_jobs(true) do
        expect{visit '/pardot/toa'}.to raise_error(/redirect is not set!/)
      end
    end

    context "redirect URL is set" do
      let(:redirect_url) { "http://www.rice.edu/" }
      around(:each) { |example|
        begin
          original_value = Settings::Pardot.toa_redirect
          Settings::Pardot.toa_redirect = redirect_url
          Settings::Db.store.object('pardot_toa_redirect').try!(:expire_cache)

          example.run
        ensure
          Settings::Pardot.toa_redirect = original_value
          Settings::Db.store.object('pardot_toa_redirect').try!(:expire_cache)
        end
      }

      context "anonymous user" do
        context "data missing" do
          scenario "non-fatal exceptions when using real BG jobs" do
            Delayed::Worker.with_delay_jobs(true) do
              visit '/pardot/toa'
              expect(current_url).to eq redirect_url
              expect(Delayed::Worker.new.work_off).to eq [0,1]
            end
          end

          scenario "exceptions are raised during the tracking" do
            expect{ visit '/pardot/toa' }.to raise_error(TrackTutorOnboardingEvent::MissingArgument)
          end
        end

        context "data present" do
          scenario "happy path" do
            happy_path_test(anonymous_user)
          end
        end
      end

      context "signed in user" do
        before(:each) { stub_current_user(user) }

        scenario "happy path with data" do
          happy_path_test(user)
        end
      end
    end

  end
end
