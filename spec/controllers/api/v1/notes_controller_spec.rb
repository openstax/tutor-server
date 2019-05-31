require 'rails_helper'
require 'vcr_helper'

RSpec.describe Api::V1::NotesController, type: :controller, api: true, version: :v1, vcr: VCR_OPTS do

  let(:application)  { FactoryBot.create :doorkeeper_application }
  let(:course)       { FactoryBot.create :course_profile_course }
  let(:period)       { FactoryBot.create :course_membership_period, course: course }
  let(:student_user)      { FactoryBot.create(:user) }
  let(:student_role)      { AddUserAsPeriodStudent[user: student_user, period: period] }
  let!(:student)          { student_role.student }

  let(:student_token)     { FactoryBot.create :doorkeeper_access_token,
                                               application: application,
                                               resource_owner_id: student_user.id }

  let(:user_2)       { FactoryBot.create(:user) }
  let(:user_2_token) { FactoryBot.create :doorkeeper_access_token,
                                         resource_owner_id: user_2.id }

  let(:note) {FactoryBot.create :content_note, role: student_role }

  let(:parameters) {
    { course_id: course.id, chapter: note.page.book_location.first, section: note.page.book_location.last }
  }

  # link page to same ecosystem as course
  before(:each) {
    note.page.chapter.book.update_attributes(ecosystem: course.ecosystem)
  }

  it 'fetches' do
    api_get :index, student_token, params: parameters
    notes = JSON.parse(response.body)
    expect(notes.count).to eq 1
    expect(notes.first['id']).to eq note.id
  end

  it 'creates' do
    expect do
      api_post :create, student_token, params: parameters, body: {
                 anchor: 'para123', contents: { test: true }
               }
      expect(response).to be_created
    end.to change { Content::Models::Note.count }
    note = Content::Models::Note.find JSON.parse(response.body)['id']
    expect(note.anchor).to eq 'para123'
  end

  it 'updates' do
    api_put :update, student_token, params: parameters.merge(id: note.id),
            body: { contents: { text: 'hello!' } }
    expect(response).to be_ok
    expect(note.reload.contents).to eq('text' => 'hello!')
  end

  it 'deletes' do
    api_delete :destroy, student_token, params: parameters.merge(id: note.id)
    expect(response).to be_ok
    expect { note.reload }.to raise_error(ActiveRecord::RecordNotFound)
  end


  it 'fetches user highlighted_sections' do
    api_get :highlighted_sections, student_token, params: parameters
    expect(response).to be_ok
  end

  it "should not fetch someone else's highlights" do
    expect do
      api_get :highlighted_sections, user_2_token, params: parameters
    end.to raise_error(SecurityTransgression)
  end

  it "should not let a user update someone else's highlights" do
    expect do
      api_put :update, user_2_token, params: parameters.merge(id: note.id),
              body: { contents: { text: 'hello!' } }
    end.to raise_error(SecurityTransgression)
  end
end
