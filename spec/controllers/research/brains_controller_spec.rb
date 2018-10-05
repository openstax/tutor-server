require 'rails_helper'

RSpec.describe Research::BrainsController, type: :controller do
  render_views

  let(:brain)  { FactoryBot.create :research_display_student_task }
  let(:cohort) { brain.cohort }
  let(:researcher) { FactoryBot.create :user, :researcher }

  before { controller.sign_in(researcher) }

  it '#index' do
    response = get :index, cohort_id: cohort.id
    expect(response.body).to include brain.name
  end

  it '#creates' do
    post :create, cohort_id: cohort.id, research_models_study_brain: {
           name: 'new', type: 'Research::Models::UpdateStudentTasked',
           code: 'puts "hello world"'
         }
    expect(Research::Models::StudyBrain.find_by(name: 'new')).not_to be_nil
  end

  it '#updates' do
    patch :update, id: brain.id, research_models_study_brain: { name: 'edited' }
    expect(brain.reload.name).to eq 'edited'
  end

  it '#destroy' do
    put :destroy, id: brain.id
    expect{ brain.reload }.to raise_error ActiveRecord::RecordNotFound
  end

end
