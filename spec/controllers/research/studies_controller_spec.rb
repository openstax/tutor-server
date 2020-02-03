require 'rails_helper'

RSpec.describe Research::StudiesController, type: :controller do
  let(:study) { FactoryBot.create :research_study }
  let(:researcher) { FactoryBot.create :user_profile, :researcher }

  before { controller.sign_in(researcher) }

  context 'PATCH #update' do
    it 'updates' do
      patch :update, params: { id: study.id, research_models_study: { name: 'edited' } }
      expect(study.reload.name).to eq 'edited'
      expect(flash[:notice]).to eq 'Study updated'
    end
  end

  it '#activate' do
    study.deactivate!
    put :activate, params: { id: study.id }
    expect(study.reload).to be_active
  end

  it '#deactivate' do
    put :deactivate, params: { id: study.id }
    expect(study.reload).to_not be_active
  end

end
