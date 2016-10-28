require 'rails_helper'

RSpec.describe Api::V1::CourseRepresenter, type: :representer do
  let(:ecosystem)        { FactoryGirl.create :content_ecosystem }

  let(:catalog_offering) do
    FactoryGirl.create :catalog_offering, salesforce_book_name: 'book',
                                          appearance_code: 'appearance',
                                          webview_url: 'web_url',
                                          pdf_url: 'pdf_url',
                                          description: 'desc',
                                          ecosystem: ecosystem
  end

  let(:course)           do
    FactoryGirl.create :entity_course, name: 'Test course',
                                       appearance_code: 'appearance override',
                                       offering: catalog_offering,
                                       is_concept_coach: true,
                                       is_college: false
  end

  subject(:represented)  { described_class.new(course).to_hash }

  it 'shows the course id' do
    expect(represented['id']).to eq course.id.to_s
  end

  it 'shows the course name' do
    expect(represented['name']).to eq 'Test course'
  end

  it 'shows the course time_zone' do
    expect(represented['time_zone']).to eq 'Central Time (US & Canada)'
  end

  it 'shows the course default open time' do
    course.profile.default_open_time = '16:08'
    expect(represented['default_open_time']).to eq '16:08'
  end

  it 'shows the course default due time' do
    course.profile.default_due_time = '16:09'
    expect(represented['default_due_time']).to eq '16:09'
  end

  it 'shows the offering salesforce_book_name' do
    expect(represented['salesforce_book_name']).to eq 'book'
  end

  it 'shows the profile appearance_code' do
    expect(represented['appearance_code']).to eq 'appearance override'
  end

  it 'shows the offering appearance_code if the profile appearance_code is blank' do
    course.profile.update_attribute(:appearance_code, nil)
    expect(represented['appearance_code']).to eq 'appearance'
  end

  it 'shows the book_pdf_url if available' do
    expect(represented['book_pdf_url']).to eq 'pdf_url'
  end

  it 'shows the webview_url if avail' do
    expect(represented['webview_url']).to eq 'web_url'
  end

  it 'shows whether or not the course is a concept coach course' do
    expect(represented['is_concept_coach']).to eq true
  end

  it 'shows whether or not it is a college course' do
    expect(represented['is_college']).to eq false
  end

  it 'shows students' do
    period = FactoryGirl.create :course_membership_period, course: course
    student_1_user = FactoryGirl.create :user
    student_2_user = FactoryGirl.create :user
    AddUserAsPeriodStudent[user: student_1_user, period: period]
    AddUserAsPeriodStudent[user: student_2_user, period: period]

    expect(represented["students"]).to(
      match_array [a_hash_including("id" => student_1_user.id.to_s),
                   a_hash_including("id" => student_2_user.id.to_s)]
    )
  end
end
