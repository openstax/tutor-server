require 'rails_helper'

RSpec.describe Research::BrainsController, type: :controller do
  render_views

  let(:brain) { FactoryBot.create :research_modified_task }
  let(:study) { brain.study }
  let(:researcher) { FactoryBot.create :user, :researcher }

  before { controller.sign_in(researcher) }

  it '#index' do
    response = get :index, study_id: study.id
    expect(response.body).to include edit_research_brain_path(brain)
  end

  it '#creates' do
    post :create, study_id: study.id, research_models_study_brain: {
           name: 'new', type: 'Research::Models::ModifiedTask',
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
