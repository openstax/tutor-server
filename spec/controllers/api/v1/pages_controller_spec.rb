require 'rails_helper'
require 'vcr_helper'

RSpec.describe Api::V1::PagesController, type: :controller, api: true,
                                         version: :v1, vcr: VCR_OPTS do
  context 'with book' do
    before(:all) do
      VCR.use_cassette("Api_V1_PagesController/with_book", VCR_OPTS) do
        @ecosystem = FetchAndImportBookAndCreateEcosystem[
          book_cnx_id: '93e2b09d-261c-4007-a987-0b3062fe154b'
        ]
      end

      @page_uuid = '95e61258-2faf-41d4-af92-f62e1414175a'
    end

    context 'GET show' do
      it 'returns not found if the version is not found' do
        api_get :show, nil, params: { ecosystem_id: @ecosystem.id, cnx_id: "#{@page_uuid}@100" }
        expect(response).to have_http_status(404)
      end

      it 'returns not found if the uuid is not found' do
        api_get :show, nil, params: {
          ecosystem_id: @ecosystem.id, cnx_id: "b5cd5a64-34a1-434e-b8ba-769000fbec30@1"
        }
        expect(response).to have_http_status(404)
      end

      it 'returns not found if the version is not a number' do
        api_get :show, nil, params: { ecosystem_id: @ecosystem.id, cnx_id: "#{@page_uuid}@x" }
        expect(response).to have_http_status(404)
      end

      it 'returns absolutized exercise urls' do
        api_get :show, nil, params: { ecosystem_id: @ecosystem.id, cnx_id: @page_uuid }

        expect(response.body_as_hash[:content_html]).not_to include(
          '#ost/api/ex/k12phys-ch04-ex001'
        )

        exercises_url_base = Rails.application.secrets.openstax[:exercises][:url]
        expect(response.body_as_hash[:content_html]).to include(
          "#{exercises_url_base}/api/exercises?q=tag%3A%22k12phys-ch04-ex001%22"
        )
      end

      context 'with an old version of force' do
        before(:all) do
          page_hash = { id: "#{@page_uuid}@2", title: 'Force' }

          book = FactoryBot.create :content_book
          @old_ecosystem = book.ecosystem
          cnx_page = OpenStax::Cnx::V1::Page.new(page_hash)
          VCR.use_cassette("Api_V1_PagesController/with_an_old_version_of_force", VCR_OPTS) do
            @old_page = Content::Routines::ImportPage.call(
              cnx_page: cnx_page, book: book, book_indices: [1, 1]
            ).outputs.page
          end
        end

        it 'returns the page with the correct uuid' do
          api_get :show, nil, params: { ecosystem_id: @old_ecosystem.id, cnx_id: @page_uuid }
          expect(response).to have_http_status(200)
          expect(response.body_as_hash).to eq(
            title: @old_page.title,
            chapter_section: @old_page.book_location,
            content_html: @old_page.content,
            spy: { ecosystem_title: @old_ecosystem.title }
          )
        end

        it 'returns the page with the correct uuid and version' do
          api_get :show, nil, params: {
            ecosystem_id: @old_ecosystem.id, cnx_id: "#{@page_uuid}@2"
          }
          expect(response).to have_http_status(200)
          expect(response.body_as_hash).to eq(
            title: @old_page.title,
            chapter_section: @old_page.book_location,
            content_html: @old_page.content,
            spy: { ecosystem_title: @old_ecosystem.title }
          )
        end
      end
    end
  end
end
