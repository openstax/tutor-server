require 'rails_helper'
require 'feature_js_helper'

RSpec.feature 'Bulk set course flag', js: true do
  before do
    admin = FactoryGirl.create(:user, :administrator)
    stub_current_user(admin)

    @course_1 = FactoryGirl.create :course_profile_course, year: 2016
    @course_2 = FactoryGirl.create :course_profile_course, year: 2017
    @course_3 = FactoryGirl.create :course_profile_course, year: 2017
  end

  scenario 'select all on page with no query' do
    visit admin_courses_path(per_page: 1)

    find('#courses_select_all_on_page').set(true)
    find('#courses_select_all_on_all_pages').set(false)

    select "Allow teacher to enable LMS", from: 'flag_name'
    select "True / Yes", from: 'flag_value'
    click_button 'Set Flag'

    flag_values = [@course_1, @course_2, @course_3].map{|course| course.reload.is_lms_enabling_allowed}

    expect(flag_values).to eq [true, false, false]

    expect(current_path).to eq(admin_courses_path)
    expect(page).to have_css('.flash_notice', text: 'Flag values were updated')
    expect(page).to have_text('LMS: enable allowed')
  end

  scenario 'select all on all pages with no query' do
    visit admin_courses_path(per_page: 1)

    find('#courses_select_all_on_all_pages').set(true)

    select "Allow teacher to enable LMS", from: 'flag_name'
    select "True / Yes", from: 'flag_value'
    click_button 'Set Flag'

    [@course_1, @course_2, @course_3].each do |course|
      expect(course.reload.is_lms_enabling_allowed).to eq true
    end

    expect(current_path).to eq(admin_courses_path)
    expect(page).to have_css('.flash_notice', text: 'Flag values were updated')
    expect(page).to have_text('LMS: enable allowed')
  end

  scenario 'select all on all pages with query' do
    visit admin_courses_path(per_page: 1, query: "year:2017")

    find('#courses_select_all_on_all_pages').set(true)

    select "Allow teacher to enable LMS", from: 'flag_name'
    select "True / Yes", from: 'flag_value'
    click_button 'Set Flag'

    flag_values = [@course_1, @course_2, @course_3].map{|course| course.reload.is_lms_enabling_allowed}
    expect(flag_values).to eq [false, true, true]


    expect(current_path).to eq(admin_courses_path)
    expect(page).to have_css('.flash_notice', text: 'Flag values were updated')
    expect(page).to have_text('LMS: enable allowed')
  end

end
