require 'rails_helper'

RSpec.feature 'DistrictTermsWork' do
  scenario 'normal creation, no deletion or editing' do
    admin = FactoryGirl.create(:user, :administrator)
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

    user   = FactoryGirl.create :user
    course = CourseProfile::Models::Course.last
    period = FactoryGirl.create :course_membership_period, course: course

    # AddUserAsPeriodStudent[user: user, period: period]

    tcs = Legal::GetTargetedContracts[applicable_to: course]
    expect(tcs.map(&:contract_name)).to eq ['hisd_special']
  end

  scenario 'switching parents around is ok' do
    district_a = SchoolDistrict::CreateDistrict[name: 'DistrictA']
    district_b = SchoolDistrict::CreateDistrict[name: 'DistrictB']

    school_c = SchoolDistrict::CreateSchool[name: 'SchoolC', district: district_a]
    school_d = SchoolDistrict::CreateSchool[name: 'SchoolD', district: district_b]

    course_e = FactoryGirl.create :course_profile_course, :process_school_change, name: 'CourseE',
                                                                          school: school_c

    course_f = FactoryGirl.create :course_profile_course, :process_school_change, name: 'CourseF',
                                                                          school: school_d

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

    admin = FactoryGirl.create(:user, :administrator)
    stub_current_user(admin)

    create_targeted_terms(contract_name: 'district_a_terms', target_name: district_a.name)
    create_targeted_terms(contract_name: 'district_b_terms', target_name: district_b.name)

    # Basic checks to provide a baseline
    expect(
      Legal::GetTargetedContracts[applicable_to: course_e].map(&:contract_name)
    ).to eq ['district_a_terms']

    expect(
      Legal::GetTargetedContracts[applicable_to: course_f].map(&:contract_name)
    ).to eq ['district_b_terms']

    # Move a course
    CourseProfile::UpdateCourse[course_e.id, {school_district_school_id: school_d.id }]

    expect(
      Legal::GetTargetedContracts[applicable_to: course_e].map(&:contract_name)
    ).to eq ['district_b_terms']

    # Move a school
    SchoolDistrict::UpdateSchool[school: school_d, name: school_d.name, district: district_a]

    expect(
      Legal::GetTargetedContracts[applicable_to: course_f].map(&:contract_name)
    ).to eq ['district_a_terms']
  end

  scenario 'blah' do
    district_a = SchoolDistrict::CreateDistrict[name: 'DistrictA']
    school_c = SchoolDistrict::CreateSchool[name: 'SchoolC', district: district_a]
    course_e = FactoryGirl.create :course_profile_course, :process_school_change, name: 'CourseE',
                                                                          school: school_c
    course_f = FactoryGirl.create :course_profile_course, :process_school_change, name: 'CourseF'

    FinePrint::Contract.create(name: 'district_a_terms', title: 'a', content: 'a').publish
    FinePrint::Contract.create(name: 'general_terms_of_use', title: 'a', content: 'a').publish
    FinePrint::Contract.create(name: 'privacy_policy', title: 'a', content: 'a').publish

    user_1 = FactoryGirl.create(:user, skip_terms_agreement: true)
    user_2 = FactoryGirl.create(:user, skip_terms_agreement:true)

    AddUserAsCourseTeacher[user: user_1, course: course_e]
    AddUserAsCourseTeacher[user: user_2, course: course_f]

    admin = FactoryGirl.create(:user, :administrator)

    stub_current_user(admin)
    create_targeted_terms(contract_name: 'district_a_terms', target_name: district_a.name,
                          masked_contracts: ['privacy_policy'], is_proxy_signed: true)

    stub_current_user(user_1)

    stub_current_user(user_1, Api::V1::TermsController)

    # User 1 should not have signed district a terms yet

    expect(FinePrint.signed_contract?(user_1.to_model, 'district_a_terms')).to be_falsy

    # Simulate the FE getting the terms listing for a user, should add an implicit signature
    # for user1 / district_a_terms

    expect{
      visit api_terms_path
    }.to change { FinePrint::Signature.count }.by(1)

    expect(FinePrint.signed_contract?(user_1.to_model, 'district_a_terms')).to be_truthy
    expect(FinePrint::Signature.all.max_by{ |sig| sig.created_at }.is_implicit?).to be_truthy

    # user 2 is not in district A, so should just see normal terms
    stub_current_user(user_2)

    # Simulate the FE getting the terms listing for a user, should NOT add an implicit signature
    expect{
      visit api_terms_path
    }.not_to change { FinePrint::Signature.count }
  end

  def create_targeted_terms(contract_name:, target_name:, is_proxy_signed: true, masked_contracts: [])
    visit admin_targeted_contracts_path
    click_link 'Add Targeted Contract'
    select contract_name, from: 'targeted_contract_contract_name'
    select target_name, from: 'targeted_contract_target'
    masked_contracts.each do |masked_contract|
      select masked_contract, from: 'targeted_contract_masked_contract_names'
    end
    check 'targeted_contract_is_proxy_signed' if is_proxy_signed
    click_button 'Submit'
  end

end
