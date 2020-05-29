require 'rails_helper'

RSpec.describe Demo::Users, type: :routine do
  let(:config_base_dir) { File.join Rails.root, 'spec', 'fixtures', 'demo' }
  let(:config_files)    do
    [
      'staff/administrators',
      'staff/content_analysts',
      'staff/customer_support',
      'staff/researchers',
      'review/apush'
    ]
  end
  let(:user_configs)    do
    config_files.map do |file|
      {
        users: Api::V1::Demo::Users::Representer.new(Demo::Mash.new).from_hash(
          YAML.load_file File.join(config_base_dir, 'users', "#{file}.yml")
        ).deep_symbolize_keys
      }
    end
  end

  it 'creates the demo users specified in the config' do
    expect do
      user_configs.each { |config| expect(described_class.call(config).errors).to be_empty }
    end.to  change { OpenStax::Accounts::Account.count }.by(11)
       .and change { User::Models::Profile.count }.by(11)

    admin = User::Models::Profile.joins(:account).find_by(account: { username: 'admin' })
    expect(admin.is_admin?).to eq true
    expect(admin.is_content_analyst?).to eq true
    expect(admin.is_customer_support?).to eq true
    expect(admin.is_researcher?).to eq true
    expect(admin.role).to eq 'other'
    expect(admin.faculty_status).to eq 'no_faculty_info'
    expect(admin.school_type).to eq 'unknown_school_type'
    expect(admin.school_location).to eq 'unknown_school_location'
    expect(admin.is_kip).to be_nil
    expect(admin.is_test).to eq true

    ca = User::Models::Profile.joins(:account).find_by(account: { username: 'content' })
    expect(ca.is_admin?).to eq false
    expect(ca.is_content_analyst?).to eq true
    expect(ca.is_customer_support?).to eq false
    expect(ca.is_researcher?).to eq false
    expect(ca.role).to eq 'other'
    expect(ca.faculty_status).to eq 'no_faculty_info'
    expect(ca.school_type).to eq 'unknown_school_type'
    expect(ca.school_location).to eq 'unknown_school_location'
    expect(ca.is_kip).to be_nil
    expect(ca.is_test).to eq true

    cs = User::Models::Profile.joins(:account).find_by(account: { username: 'support' })
    expect(cs.is_admin?).to eq false
    expect(cs.is_content_analyst?).to eq false
    expect(cs.is_customer_support?).to eq true
    expect(cs.is_researcher?).to eq false
    expect(cs.role).to eq 'other'
    expect(cs.faculty_status).to eq 'no_faculty_info'
    expect(cs.school_type).to eq 'unknown_school_type'
    expect(cs.school_location).to eq 'unknown_school_location'
    expect(cs.is_kip).to be_nil
    expect(cs.is_test).to eq true

    rs = User::Models::Profile.joins(:account).find_by(account: { username: 'researcher' })
    expect(rs.is_admin?).to eq false
    expect(rs.is_content_analyst?).to eq false
    expect(rs.is_customer_support?).to eq false
    expect(rs.is_researcher?).to eq true
    expect(rs.role).to eq 'other'
    expect(rs.faculty_status).to eq 'no_faculty_info'
    expect(rs.school_type).to eq 'unknown_school_type'
    expect(rs.school_location).to eq 'unknown_school_location'
    expect(rs.is_kip).to be_nil
    expect(rs.is_test).to eq true

    tc = User::Models::Profile.joins(:account).find_by(account: { username: 'reviewteacher' })
    expect(tc.is_admin?).to eq false
    expect(tc.is_content_analyst?).to eq false
    expect(tc.is_customer_support?).to eq false
    expect(tc.is_researcher?).to eq false
    expect(tc.role).to eq 'instructor'
    expect(tc.faculty_status).to eq 'confirmed_faculty'
    expect(tc.school_type).to eq 'college'
    expect(tc.school_location).to eq 'domestic_school'
    expect(tc.is_kip).to eq true
    expect(tc.is_test).to eq true

    acc = OpenStax::Accounts::Account.arel_table
    students = User::Models::Profile.joins(:account).where(acc[:username].matches('reviewstudent%'))
    expect(students.size).to eq 6
    students.each do |student|
      expect(student.is_admin?).to eq false
      expect(student.is_content_analyst?).to eq false
      expect(student.is_customer_support?).to eq false
      expect(student.is_researcher?).to eq false
      expect(student.role).to eq 'student'
      expect(student.faculty_status).to eq 'no_faculty_info'
      expect(student.school_type).to eq 'college'
      expect(student.school_location).to eq 'domestic_school'
      expect(student.is_kip).to eq true
      expect(student.is_test).to eq true
    end
  end
end
