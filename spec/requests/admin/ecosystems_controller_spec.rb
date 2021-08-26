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

  context 'GET #new' do
    it 'provides information about ecosystems that can be imported' do
      get new_admin_ecosystem_url

      expect(assigns[:pipeline_versions]).to eq [
        '20210713.205645',
        '20210623.195337',
        '20210514.171726',
        '20210421.141058',
        '20210325.214454',
        '20210224.204120',
        '20201222.172624',
        '20201029.133542',
        '20201014.233724',
        '20200827.155539'
      ]
      expect(assigns[:pipeline_version]).to eq '20210713.205645'
      expect(assigns[:collections]).to eq [
        [ 'Anatomy and physiology - col11496', 'col11496' ],
        [ 'Biology - col11448', 'col11448' ],
        [ 'Biology 2e - col24361', 'col24361' ],
        [ 'Biology ap courses - col12078', 'col12078' ],
        [ 'College physics - col11406', 'col11406' ],
        [ 'College physics ap courses - col11844', 'col11844' ],
        [ 'College physics courseware - col12006', 'col12006' ],
        [ 'Concepts biology - col11487', 'col11487' ],
        [ 'Entrepreneurship - col29104', 'col29104' ],
        [ 'Física universitaria volumen 1 - col33393', 'col33393' ],
        [ 'Introduction sociology - col11407', 'col11407' ],
        [ 'Introduction sociology 2e - col11762', 'col11762' ],
        [ 'Introduction sociology 3e - col32649', 'col32649' ],
        [ 'Life liberty and pursuit happiness - col31596', 'col31596' ],
        [ 'Physics - col12081', 'col12081' ],
        [ 'Psychology - col11629', 'col11629' ],
        [ 'Psychology 2e - col31502', 'col31502' ],
        [ 'University physics volume 1 - col12031', 'col12031' ],
        [ 'University physics volume 2 - col12074', 'col12074' ],
        [ 'University physics volume 3 - col12067', 'col12067' ],
        [ 'Us history - col11740', 'col11740' ]
      ]
      expect(assigns[:reading_processing_instructions]).to eq <<~EOS
        ---
        - css: ".summary, .interactive-exercise, .multiple-choice, .free-response, .references"
          fragments: []
        - css: ".note"
          fragments:
          - reading
          labels:
          - note
        - css: ".anatomy.interactive"
          fragments:
          - interactive
          labels:
          - interactive link
      EOS
      expect(assigns[:content_versions]).to eq [ '22.38', '22.8' ]
      expect(assigns[:content_version]).to eq '22.38'
    end
  end

  context 'POST #create' do
    context 'tutor book' do
      let(:pipeline_version)                { '0.1' }
      let(:collection_id)                   { 'col00000' }
      let(:book_uuid)                       { '93e2b09d-261c-4007-a987-0b3062fe154b' }
      let(:content_version)                 { '4.4' }
      let(:reading_processing_instructions) do
        YAML.load_file('config/reading_processing_instructions.yml')['college-physics'].to_yaml
      end

      it 'imports the book into an ecosystem' do
        expect_any_instance_of(OpenStax::Content::Abl).to receive(:approved_books).and_return(
          [ collection_id: collection_id, books: [ uuid: book_uuid ] ]
        )

        expect do
          post admin_ecosystems_url, params: {
            pipeline_version: pipeline_version,
            collection_id: collection_id,
            content_version: content_version,
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
