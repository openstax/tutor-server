require 'rails_helper'

RSpec.feature 'DistrictTermsWork' do
  scenario 'normal creation, no deletion or editing' do
    admin = FactoryGirl.create(:user_profile, :administrator)
    stub_current_user(admin)

    visit admin_districts_path
    click_link 'Add district'

    fill_in 'Name', with: 'HISD'
    click_button 'Save'

    visit admin_schools_path
    click_link 'Add school'

    fill_in 'Name', with: 'JFK'
    select 'HISD', from: 'District'
    click_button 'Save'

    visit admin_courses_path
    click_link 'Add Course'

    fill_in 'Name', with: 'Hello World'
    select 'JFK', from: 'School'
    click_button 'Save'

    contract = FinePrint::Contract.create(
      name: 'hisd_special',
      title: 'Terms of Use and Privacy Policy',
      content: 'blah'
    )

    contract.publish

    visit admin_targeted_contracts_path
    click_link 'Add Targeted Contract'
    select 'hisd_special', from: 'targeted_contract_contract_name'
    select 'HISD', from: 'targeted_contract_target'
    check 'targeted_contract_is_proxy_signed'
    click_button 'Submit'

    user = Entity::User.create!
    course = Entity::Course.first
    period = CreatePeriod[course: course]

    # AddUserAsPeriodStudent[user: user, period: period]

    tcs = Legal::GetTargetedContracts[applicable_to: course]
    expect(tcs.collect(&:contract_name)).to eq ['hisd_special']
  end

  scenario 'switching parents around is ok' do
    district_a = SchoolDistrict::CreateDistrict[name: 'DistrictA']
    district_b = SchoolDistrict::CreateDistrict[name: 'DistrictB']

    school_c = SchoolDistrict::CreateSchool[name: 'SchoolC', district: district_a]
    school_d = SchoolDistrict::CreateSchool[name: 'SchoolD', district: district_b]

    course_e = CreateCourse[name: 'CourseE', school: school_c]
    course_f = CreateCourse[name: 'CourseF', school: school_d]

    FinePrint::Contract.create(
      name: 'district_a_terms',
      title: 'Terms of Use and Privacy Policy',
      content: 'blah'
    ).publish

    FinePrint::Contract.create(
      name: 'district_b_terms',
      title: 'Terms of Use and Privacy Policy',
      content: 'blah'
    ).publish

    admin = FactoryGirl.create(:user_profile, :administrator)
    stub_current_user(admin)

    create_targeted_terms('district_a_terms', district_a.name)
    create_targeted_terms('district_b_terms', district_b.name)

    # Basic checks to provide a baseline
    expect(Legal::GetTargetedContracts[applicable_to: course_e]
          .collect(&:contract_name))
          .to eq ['district_a_terms']

    expect(Legal::GetTargetedContracts[applicable_to: course_f]
          .collect(&:contract_name))
          .to eq ['district_b_terms']

    # Move a course
    CourseProfile::UpdateProfile[course_e.id, {school_district_school_id: school_d.id }]

    expect(Legal::GetTargetedContracts[applicable_to: course_e]
          .collect(&:contract_name))
          .to eq ['district_b_terms']

    # Move a school
    SchoolDistrict::UpdateSchool[id: school_d.id, attributes: {school_district_district_id: district_a.id}]

    expect(Legal::GetTargetedContracts[applicable_to: course_f]
          .collect(&:contract_name))
          .to eq ['district_a_terms']
  end

  def create_targeted_terms(contract_name, target_name, is_proxy_signed = true)
    visit admin_targeted_contracts_path
    click_link 'Add Targeted Contract'
    select contract_name, from: 'targeted_contract_contract_name'
    select target_name, from: 'targeted_contract_target'
    check 'targeted_contract_is_proxy_signed'
    click_button 'Submit'
  end

end
