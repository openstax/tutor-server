require 'rails_helper'

RSpec.describe User::Models::Profile, type: :model do
  subject(:profile) { FactoryBot.create(:user_profile) }

  it { is_expected.to belong_to(:account) }

  it { is_expected.to have_one(:administrator).dependent(:destroy) }

  it 'must enforce that one account is only used by one user' do
    profile_2 = FactoryBot.build(:user_profile)
    profile_2.account = profile.account
    expect(profile_2).to_not be_valid
  end

  [
    :username, :first_name, :last_name, :full_name, :title, :name, :casual_name, :role,
    :salesforce_contact_id, :faculty_status, :grant_tutor_access, :school_type, :school_location
  ].each { |method| it { is_expected.to delegate_method(method).to(:account) } }

  [:first_name=, :last_name=, :full_name=, :title=].each do |method|
    it { is_expected.to delegate_method(method).to(:account).with_arguments('foo') }
  end

  it 'enforces length of ui_settings' do
    profile = FactoryBot.build(:user_profile)
    profile.ui_settings = {test: ('a' * 10_001)}
    expect(profile).to_not be_valid
    expect(profile.errors[:ui_settings].to_s).to include 'too long'
  end

  context '#can_create_courses?' do
    before(:all) do
      DatabaseCleaner.start

      @course = FactoryBot.create :course_profile_course
      @period = FactoryBot.create :course_membership_period, course: @course

      @anonymous = User::Models::Profile.anonymous
      @user = FactoryBot.create :user_profile
      @student = FactoryBot.create :user_profile
      @faculty = FactoryBot.create :user_profile

      AddUserAsPeriodStudent[period: @period, user: @student]
      AddUserAsCourseTeacher[course: @course, user: @faculty]

      @faculty.account.confirmed_faculty!
    end

    before do
      @course.reload
      @period.reload

      @anonymous.reload
      @user.reload
      @student.reload
      @faculty.reload
    end

    after(:all) { DatabaseCleaner.clean }

    context 'anonymous user' do
      let(:user) { @anonymous }

      it 'should eq false' do
        expect(user.can_create_courses?).to eq false
      end
    end

    context 'regular user' do
      let(:user) { @user }

      it 'should eq false' do
        expect(user.can_create_courses?).to eq false
      end
    end

    context 'student' do
      let(:user) { @student }

      it 'should eq false' do
        expect(user.can_create_courses?).to eq false
      end
    end

    context 'grant_tutor_access' do
      let(:user) { @user }

      before { user.account.update_attribute :grant_tutor_access, true }

      it 'should eq true' do
        expect(user.can_create_courses?).to eq true
      end
    end

    context 'confirmed faculty' do
      let(:user) { @faculty }

      [ :college, :high_school, :k12_school, :home_school ].each do |school_type|
        context school_type.to_s do
          before { user.account.update_attribute :school_type, school_type }

          it 'should eq true' do
            expect(user.can_create_courses?).to eq true
          end
        end
      end

      [ :other_school_type ].each do |school_type|
        context school_type.to_s do
          before { user.account.update_attribute :school_type, school_type }

          it 'should eq false' do
            expect(user.can_create_courses?).to eq false
          end
        end
      end

      context 'foreign_school school_location' do
        before do
          user.account.college!
          user.account.foreign_school!
        end

        it 'should eq false' do
          expect(user.can_create_courses?).to eq false
        end
      end
    end
  end
end
