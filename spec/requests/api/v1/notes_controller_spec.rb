require 'rails_helper'
require 'vcr_helper'

RSpec.describe Api::V1::NotesController, type: :request, api: true, version: :v1 do
  let(:application)   { FactoryBot.create :doorkeeper_application }
  let(:course)        { FactoryBot.create :course_profile_course }
  let(:period)        { FactoryBot.create :course_membership_period, course: course }
  let(:student_user)  { FactoryBot.create :user_profile }
  let(:student_role)  { AddUserAsPeriodStudent[user: student_user, period: period] }
  let!(:student)      { student_role.student }

  let!(:unassigned_role) do
    FactoryBot.create :entity_role, profile: student_user, role_type: :unassigned
  end
  let!(:default_role)    do
    FactoryBot.create :entity_role, profile: student_user, role_type: :default
  end

  let(:student_token) do
    FactoryBot.create :doorkeeper_access_token, application: application,
                                                resource_owner_id: student_user.id
  end

  let(:user_2)        { FactoryBot.create(:user_profile) }
  let(:user_2_token)  { FactoryBot.create :doorkeeper_access_token, resource_owner_id: user_2.id }

  let(:note)          { FactoryBot.create :content_note, role: student_role }

  # link page to same ecosystem as course
  before(:each) { note.page.book.update_attributes(ecosystem: course.ecosystem) }

  context 'GET #index' do
    it "fetches the user's notes" do
      api_get api_page_notes_url(note.page.uuid), student_token

      expect(response).to be_ok
      notes = JSON.parse(response.body)
      expect(notes.count).to eq 1
      expect(notes.first['id']).to eq note.id
    end

    it "does not fetch someone else's notes" do
      api_get api_page_notes_url(note.page.uuid), user_2_token

      expect(response).to be_ok
      notes = JSON.parse(response.body)
      expect(notes.count).to eq 0
    end
  end

  context 'POST #create' do
    it 'creates a note' do
      expect do
        api_post api_page_notes_url(note.page.uuid), student_token, params: {
                   course_id: course.id, anchor: 'para123', contents: { test: true }
                 }.to_json
      end.to change { Content::Models::Note.count }

      expect(response).to be_created
      note = Content::Models::Note.find JSON.parse(response.body)['id']
      expect(note.anchor).to eq 'para123'
      expect(note.role).to eq student_role
    end
  end

  context 'PUT #update' do
    it 'updates a note' do
      api_put api_note_url(note.id), student_token, params: { contents: { text: 'hello!' } }.to_json

      expect(response).to be_ok
      expect(note.reload.contents).to eq('text' => 'hello!')
    end

    it "does not let a user update someone else's notes" do
      expect do
        api_put api_note_url(note.id), user_2_token,
                params: { contents: { text: 'hello!' } }.to_json
      end.to raise_error(SecurityTransgression)
    end
  end

  context 'DELETE #destroy' do
    it 'deletes a note' do
      api_delete api_note_url(note.id), student_token

      expect(response).to be_ok
      expect { note.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "does not let a user delete someone else's notes" do
      expect do
        api_delete api_note_url(note.id), user_2_token
      end.to raise_error(SecurityTransgression)
    end
  end

  context 'GET #highlighted_sections' do
    def highlighted_sections_api_book_path(book_uuid)
      "/api/books/#{book_uuid}/highlighted_sections"
    end

    it 'fetches user highlighted_sections' do
      api_get highlighted_sections_api_book_path(note.page.book.uuid), student_token

      expect(response).to be_ok
      expect(response.body_as_hash[:pages]).not_to be_empty
    end

    it "does not fetch someone else's highlights" do
      api_get highlighted_sections_api_book_path(note.page.book.uuid), user_2_token

      expect(response).to be_ok
      expect(response.body_as_hash[:pages]).to be_empty
    end

    it 'does not fetch duplicates' do
      new_note = FactoryBot.create :content_note, role: student_role
      new_note.page.update_attributes! uuid: note.page.uuid
      new_note.page.book.update_attributes! uuid: note.page.book.uuid

      api_get highlighted_sections_api_book_path(note.page.book.uuid), student_token

      expect(response).to be_ok
      expect(response.body_as_hash[:pages].length).to eq 1
    end
  end
end
