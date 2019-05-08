require 'rails_helper'

RSpec.describe ImportRoster, type: :routine do
  let(:period)      { FactoryBot.create :course_membership_period }
  let(:num_users)   { 10 }
  let(:user_hashes) do
    num_users.times.map do
      first_name = Faker::Name.first_name
      last_name = Faker::Name.last_name

      {
        username: "#{first_name.downcase}_#{last_name.downcase}",
        password: SecureRandom.base64,
        first_name: first_name,
        last_name: last_name
      }
    end
  end

  let(:result)      { described_class.call(user_hashes: user_hashes, period: period) }

  before            do
    reassign = ReassignPublishedPeriodTaskPlans.new
    expect(ReassignPublishedPeriodTaskPlans).to receive(:new).and_return(reassign)
    expect(reassign).to receive(:exec).with(period: period).once
    expect(OpenStax::Biglearn::Api).to receive(:update_rosters).with(course: period.course).once
  end

  it 'imports the given user hashes into the given period' do
    expect { result }.to  change { User::Models::Profile.count }.by(num_users)
                     .and change { OpenStax::Accounts::Account.count }.by(num_users)
                     .and change { Entity::Role.count }.by(num_users)
                     .and change { CourseMembership::Models::Student.count }.by(num_users)
                     .and change { CourseMembership::Models::Enrollment.count }.by(num_users)

    new_users = User::Models::Profile.order(:created_at).preload(
      roles: { student: :period }
    ).last(num_users)
    new_users.each do |new_user|
      expect(new_user.roles.first.student.period).to eq period
    end
  end

  it 'sets the new users to have the student role' do
    result
    expect(OpenStax::Accounts::Account.find_by(username: user_hashes[0][:username]).role).to eq 'student'
  end

  it 'does not overwrite existing users\' info' do
    existing_users = user_hashes.map do |user_hash|
      FactoryBot.create :user, username: user_hash[:username]
    end

    expect { result }.to  not_change { User::Models::Profile.count }
                     .and not_change { OpenStax::Accounts::Account.count }
                     .and change { Entity::Role.count }.by(num_users)
                     .and change { CourseMembership::Models::Student.count }.by(num_users)
                     .and change { CourseMembership::Models::Enrollment.count }.by(num_users)

    existing_users.each do |user|
      first_name = user.first_name
      last_name = user.last_name

      user.to_model.reload

      expect(user.first_name).to eq first_name
      expect(user.last_name).to eq last_name
    end
  end
end
