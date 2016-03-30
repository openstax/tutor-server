require 'rails_helper'
require 'vcr_helper'

RSpec.describe Admin::EcosystemsController, type: :controller, speed: :slow, vcr: VCR_OPTS do
  let!(:admin) { FactoryGirl.create(:user, :administrator) }

  let!(:book_1) { FactoryGirl.create :content_book, title: 'Physics', version: '1' }
  let!(:ecosystem_1) { Content::Ecosystem.find(book_1.ecosystem.id) }
  let!(:book_2) { FactoryGirl.create :content_book, title: 'AP Biology', version: '2' }
  let!(:ecosystem_2) { Content::Ecosystem.find(book_2.ecosystem.id) }

  let!(:course) { CreateCourse[name: 'AP Biology'] }

  before { controller.sign_in(admin) }

  describe 'GET #index' do
    it 'lists ecosystems' do
      get :index

      expected_ecosystems = [book_2.ecosystem, book_1.ecosystem].collect do |content_ecosystem|
        strategy = ::Content::Strategies::Direct::Ecosystem.new(content_ecosystem)
        ::Content::Ecosystem.new(strategy: strategy)
      end
      expect(assigns[:ecosystems]).to eq expected_ecosystems
    end
  end

  describe 'POST #create' do
    it 'imports a tutor ecosystem from a manifest' do
      fixture_path = 'content/sample_tutor_manifest.yml'
      manifest = fixture_file_upload(fixture_path)
      expect {
        post :create, ecosystem: { manifest: manifest }
      }.to change{ Content::Models::Ecosystem.count }.by(1)
      expect(flash[:notice]).to eq('Ecosystem import job queued.')
    end

    it 'imports a concept coach ecosystem from a manifest' do
      fixture_path = 'content/sample_cc_manifest.yml'
      manifest = fixture_file_upload(fixture_path)
      expect {
        post :create, ecosystem: { manifest: manifest }
      }.to change{ Content::Models::Ecosystem.count }.by(1)
      expect(flash[:notice]).to eq('Ecosystem import job queued.')
    end
  end

  describe '#destroy' do
    it 'deletes an ecosystem' do
      expect {
        delete :destroy, id: ecosystem_1.id
      }.to change { Content::Models::Ecosystem.count }.by(-1)
      expect(flash[:notice]).to eq('Ecosystem deleted.')
      expect(flash[:error]).to be_nil
    end

    it 'returns an error if the ecosystem is linked to a course' do
      AddEcosystemToCourse[course: course, ecosystem: ecosystem_2]
      expect {
        delete :destroy, id: ecosystem_2.id
      }.to_not change { Content::Models::Ecosystem.count }
      expect(flash[:notice]).to be_nil
      expect(flash[:error]).to eq(
        'The ecosystem cannot be deleted because it is linked to a course')
    end
  end
end
