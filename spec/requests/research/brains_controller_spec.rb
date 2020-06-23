require 'rails_helper'

RSpec.describe Research::BrainsController, type: :request do
  let(:brain) { FactoryBot.create :research_modified_task }
  let(:study) { brain.study }
  let(:researcher) { FactoryBot.create :user_profile, :researcher }

  before { sign_in! researcher }

  it '#index' do
    get research_study_brains_url(study.id)
    expect(response.body).to include edit_research_brain_path(brain)
  end

  it '#creates' do
    post research_study_brains_url(study.id), params: {
      research_models_study_brain: {
        name: 'new',
        type: 'Research::Models::ModifiedTask',
        code: 'puts "hello world"'
      }
    }
    expect(Research::Models::StudyBrain.find_by(name: 'new')).not_to be_nil
  end

  it '#updates' do
    patch research_brain_url(brain.id), params: { research_models_study_brain: { name: 'edited' } }
    expect(brain.reload.name).to eq 'edited'
  end

  it '#destroy' do
    delete research_brain_url(brain.id)
    expect { brain.reload }.to raise_error ActiveRecord::RecordNotFound
  end
end
