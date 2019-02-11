require 'rails_helper'
require 'vcr_helper'

RSpec.describe Api::V1::NotesController, type: :controller, api: true, version: :v1, vcr: VCR_OPTS do

  let(:course)       { FactoryBot.create :course_profile_course }
  let(:period)       { FactoryBot.create :course_membership_period, course: course }
  let(:user_1)       { FactoryBot.create(:user) }

  let(:user_1_role)  { AddUserAsPeriodStudent[period: period, user: user_1] }

  let(:user_1_token) { FactoryBot.create :doorkeeper_access_token,
                                         resource_owner_id: user_1_role.student.id }

  let(:user_2)       { FactoryBot.create(:user) }
  let(:user_2_token) { FactoryBot.create :doorkeeper_access_token,
                                         resource_owner_id: user_2.id }

  let(:note) {FactoryBot.create :notes_note, role: user_1_role }

  context 'happy path' do
    it 'fetches' do
      api_get :index, user_1_token, parameters: {
                course_id: course.id, page_id: note.page.id
              }
      notes = JSON.parse(response.body)
      expect(notes.count).to eq 1
      expect(notes.first).to eq Api::V1::NoteRepresenter.new(note).as_json
    end

    it 'saves' do
      expect{
        api_post :create, user_1_token, parameters: {
                   course_id: course.id, page_id: note.page.id,
                 }, raw_post_data: {
                   anchor: 'para123', contents: { test: true }
                 }
        expect(response).to be_ok
      }.to change { Notes::Models::Note.count }
      note = Notes::Models::Note.find JSON.parse(response.body)['id']
      expect(note.anchor).to eq 'para123'
    end

    it 'updates' do
        api_put :update, user_1_token, parameters: {
                  id: note.id, course_id: course.id, page_id: note.page.id,
                }, raw_post_data: { contents: { text: 'hello!' } }
        expect(response).to be_ok
        expect(note.reload.contents).to eq('text' => 'hello!')
    end

    it 'deletes' do
      api_delete :destroy, user_1_token, parameters: {
                   course_id: course.id, id: note.id
                 }
      expect(response).to be_ok
      expect{ note.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

  end
end
