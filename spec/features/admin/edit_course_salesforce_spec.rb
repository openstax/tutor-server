require 'rails_helper'
require 'vcr_helper'

RSpec.feature 'Admin changing course Salesforce settings' do
  background do
    @course = FactoryBot.create :course_profile_course
    @period_1 = FactoryBot.create :course_membership_period, course: @course

    admin = FactoryBot.create(:user_profile, :administrator)
    stub_current_user(admin)
  end

  scenario 'set excluded from salesforce' do
    go_to_salesforce_tab
    expect(page).to have_unchecked_field('course_is_excluded_from_salesforce')
    check 'course_is_excluded_from_salesforce'
    click_button 'exclusion_save'
    expect(@course.reload.is_excluded_from_salesforce).to eq true
    go_to_salesforce_tab
    expect(page).to have_checked_field('course_is_excluded_from_salesforce')
  end

  def go_to_salesforce_tab
    visit edit_admin_course_path(@course)
    find("a[href='#salesforce']").click
    expect(page).to have_content('Salesforce Records')
  end

end
