require 'rails_helper'
require 'vcr_helper'

RSpec.describe Admin::EcosystemsController, type: :request, vcr: VCR_OPTS, speed: :medium do
  let(:admin)        { FactoryBot.create(:user_profile, :administrator) }

  let(:book_1)       { FactoryBot.create :content_book, title: 'Physics', version: '1' }
  let!(:ecosystem_1) { Content::Models::Ecosystem.find(book_1.ecosystem.id) }
  let(:book_2)       { FactoryBot.create :content_book, title: 'AP Biology', version: '2' }
  let!(:ecosystem_2) { Content::Models::Ecosystem.find(book_2.ecosystem.id) }

  let(:course)       { FactoryBot.create :course_profile_course }

  before { sign_in! admin }

  context 'GET #index' do
    it 'lists ecosystems' do
      get admin_ecosystems_url

      expected_ecosystems = [book_2.ecosystem, book_1.ecosystem]
      expect(assigns[:ecosystems]).to eq expected_ecosystems
    end
  end

  context 'POST #create' do
    context 'tutor manifest' do
      let(:manifest_path)  { 'content/sample_manifest.yml' }
      let(:manifest_file) { fixture_file_upload(manifest_path) }

      it 'imports the manifest into an ecosystem' do
        expect do
          post admin_ecosystems_url, params: { ecosystem: { manifest: manifest_file } }
        end.to change{ Content::Models::Ecosystem.count }.by(1)
        expect(flash[:notice]).to eq('Ecosystem import job queued.')
      end

      it 'can update the manifest book version' do
        expect(ImportEcosystemManifest).to receive(:perform_later) do |params|
          expect(params[:manifest].books.first.cnx_id).not_to include('@')
        end
        expect(Jobba).to receive(:find).and_return(instance_spy(Jobba::Status))

        post admin_ecosystems_url,
             params: { ecosystem: { manifest: manifest_file, books: 'update' } }
        expect(flash[:notice]).to eq('Ecosystem import job queued.')
      end

      it 'can update the manifest exercise versions' do
        expect(ImportEcosystemManifest).to receive(:perform_later) do |params|
          expect(params[:manifest].books.first.exercise_ids).not_to be_empty
          params[:manifest].books.first.exercise_ids.each do |exercise_id|
            expect(exercise_id).not_to include('@')
          end
        end
        expect(Jobba).to receive(:find).and_return(instance_spy(Jobba::Status))

        post admin_ecosystems_url,
             params: { ecosystem: { manifest: manifest_file, exercises: 'update' } }
        expect(flash[:notice]).to eq('Ecosystem import job queued.')
      end

      it 'can update the manifest exercise numbers and versions' do
        expect(ImportEcosystemManifest).to receive(:perform_later) do |params|
          expect(params[:manifest].books.first.exercise_ids).to be_blank
        end
        expect(Jobba).to receive(:find).and_return(instance_spy(Jobba::Status))

        post admin_ecosystems_url,
             params: { ecosystem: { manifest: manifest_file, exercises: 'discard' } }
        expect(flash[:notice]).to eq('Ecosystem import job queued.')
      end
    end
  end

  context '#destroy' do
    it 'deletes an ecosystem' do
      expect do
        delete admin_ecosystem_url(ecosystem_1.id)
      end.to change { ecosystem_1.reload.deleted? }.from(false).to(true)
      expect(flash[:notice]).to eq('Ecosystem deleted.')
      expect(flash[:error]).to be_nil
    end

    it 'returns an error if the ecosystem is linked to a course' do
      AddEcosystemToCourse[course: course, ecosystem: ecosystem_2]
      expect do
        delete admin_ecosystem_url(ecosystem_2.id)
      end.to_not change { Content::Models::Ecosystem.count }
      expect(flash[:notice]).to be_nil
      expect(flash[:error]).to eq(
        'The ecosystem cannot be deleted because it is linked to a course')
    end
  end

  context 'GET #manifest' do
    it 'allows the ecosystem\'s manifest to be downloaded' do
      get manifest_admin_ecosystem_url(ecosystem_1.id)

      expected_content_disposition = \
        "attachment; filename=\"#{FilenameSanitizer.sanitize(ecosystem_1.title)}.yml\""
      expect(response.headers['Content-Disposition']).to eq expected_content_disposition
      expect(response.body).to eq ecosystem_1.manifest.to_yaml
    end
  end
end
