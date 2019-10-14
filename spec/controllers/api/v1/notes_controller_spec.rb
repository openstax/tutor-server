require 'rails_helper'
require 'vcr_helper'

RSpec.describe Api::V1::NotesController, type: :controller, api: true, version: :v1 do

  let(:application)   { FactoryBot.create :doorkeeper_application }
  let(:course)        { FactoryBot.create :course_profile_course }
  let(:period)        { FactoryBot.create :course_membership_period, course: course }
  let(:student_user)  { FactoryBot.create(:user) }
  let(:student_role)  { AddUserAsPeriodStudent[user: student_user, period: period] }
  let!(:student)      { student_role.student }

  let(:student_token) do
    FactoryBot.create :doorkeeper_access_token, application: application,
                                                resource_owner_id: student_user.id
  end

  let(:user_2)        { FactoryBot.create(:user) }
  let(:user_2_token)  { FactoryBot.create :doorkeeper_access_token, resource_owner_id: user_2.id }

  let(:note)          { FactoryBot.create :content_note, role: student_role }

  let(:index_create_params)         { { page_id: note.page.uuid } }
  let(:update_delete_params)        { { id: note.id } }
  let(:highlighted_sections_params) { { book_uuid: note.page.book.uuid } }

  # link page to same ecosystem as course
  before(:each) { note.page.chapter.book.update_attributes(ecosystem: course.ecosystem) }

  context 'GET #index' do
    it "fetches the user's notes" do
      api_get :index, student_token, params: index_create_params

      expect(response).to be_ok
      notes = JSON.parse(response.body)
      expect(notes.count).to eq 1
      expect(notes.first['id']).to eq note.id
    end

    it "does not fetch someone else's notes" do
      api_get :index, user_2_token, params: index_create_params

      expect(response).to be_ok
      notes = JSON.parse(response.body)
      expect(notes.count).to eq 0
    end
  end

  context 'POST #create' do
    it 'creates a note' do
      expect do
        api_post :create, student_token, params: index_create_params, body: {
                   course_id: course.id, anchor: 'para123', contents: { test: true }
                 }
      end.to change { Content::Models::Note.count }

      expect(response).to be_created
      note = Content::Models::Note.find JSON.parse(response.body)['id']
      expect(note.anchor).to eq 'para123'
      expect(note.role).to eq student_role
    end
  end

  context 'PUT #update' do
    it 'updates a note' do
      api_put :update, student_token, params: update_delete_params,
                                      body: { contents: { text: 'hello!' } }

      expect(response).to be_ok
      expect(note.reload.contents).to eq('text' => 'hello!')
    end

    it "does not let a user update someone else's notes" do
      expect do
        api_put :update, user_2_token, params: update_delete_params,
                                       body: { contents: { text: 'hello!' } }
      end.to raise_error(SecurityTransgression)
    end
  end

  context 'DELETE #destroy' do
    it 'deletes a note' do
      api_delete :destroy, student_token, params: update_delete_params

      expect(response).to be_ok
      expect { note.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "does not let a user delete someone else's notes" do
      expect do
        api_delete :destroy, user_2_token, params: update_delete_params
      end.to raise_error(SecurityTransgression)
    end
  end

  context 'GET #highlighted_sections' do
    it 'fetches user highlighted_sections' do
      api_get :highlighted_sections, student_token, params: highlighted_sections_params

      expect(response).to be_ok
      expect(response.body_as_hash[:pages]).not_to be_empty
    end

    it "does not fetch someone else's highlights" do
      api_get :highlighted_sections, user_2_token, params: highlighted_sections_params

      expect(response).to be_ok
      expect(response.body_as_hash[:pages]).to be_empty
    end
  end

end
