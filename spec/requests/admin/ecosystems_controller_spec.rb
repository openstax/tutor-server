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
    context 'tutor book' do
      let(:archive_version)                 { '0.1' }
      let(:collection_id)                   { 'col00000' }
      let(:book_uuid)                       { '93e2b09d-261c-4007-a987-0b3062fe154b' }
      let(:book_version)                    { '4.4' }
      let(:reading_processing_instructions) do
        YAML.load_file('config/reading_processing_instructions.yml')['college-physics'].to_yaml
      end

      it 'imports the book into an ecosystem' do
        expect_any_instance_of(OpenStax::Content::Abl).to receive(:approved_books).and_return(
          [ collection_id: collection_id, books: [ uuid: book_uuid ] ]
        )

        expect do
          post admin_ecosystems_url, params: {
            archive_version: archive_version,
            collection_id: collection_id,
            book_version: book_version,
            reading_processing_instructions: reading_processing_instructions
          }
        end.to change { Content::Models::Ecosystem.count }.by(1)
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
