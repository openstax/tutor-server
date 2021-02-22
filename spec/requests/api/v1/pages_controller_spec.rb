require 'rails_helper'
require 'vcr_helper'

RSpec.describe Api::V1::PagesController, type: :request, api: true, version: :v1, vcr: VCR_OPTS do
  context 'with book' do
    before(:all) do
      @ecosystem = generate_mini_ecosystem
      @page_uuid = 'b0ffd0a2-9c83-4d73-b899-7f2ade2acda6'
    end

    context '#show' do
      def page_api_ecosystem_path(ecosystem_id, cnx_id)
        "/api/ecosystems/#{ecosystem_id}/pages/#{cnx_id}"
      end

      it 'returns not found if the version is not found' do
        api_get page_api_ecosystem_path(@ecosystem.id, "#{@page_uuid}@100"), nil
        expect(response).to have_http_status(404)
      end

      it 'returns not found if the uuid is not found' do
        api_get page_api_ecosystem_path(@ecosystem.id, 'b5cd5a64-34a1-434e-b8ba-769000fbec30@1'),
                nil
        expect(response).to have_http_status(404)
      end

      it 'returns not found if the version is not a number' do
        api_get page_api_ecosystem_path(@ecosystem.id, "#{@page_uuid}@x"), nil
        expect(response).to have_http_status(404)
      end

      context 'with an old version of force' do
        before(:all) do
          page_hash = { id: "#{@page_uuid}@2", title: 'Force' }

          book = FactoryBot.create :content_book
          @old_ecosystem = book.ecosystem
          cnx_page = OpenStax::Cnx::V1::Page.new(page_hash)
          VCR.use_cassette("Api_V1_PagesController/with_an_old_version_of_force", VCR_OPTS) do
            @old_page = Content::Routines::ImportPage.call(
              cnx_page: cnx_page,
              book: book,
              book_indices: [1, 1],
              parent_book_part_uuid: SecureRandom.uuid
            ).outputs.page
          end
        end

        it 'returns the page with the correct uuid' do
          api_get page_api_ecosystem_path(@old_ecosystem.id, @page_uuid), nil
          expect(response).to have_http_status(200)
          expect(response.body_as_hash).to eq(
            title: @old_page.title,
            chapter_section: @old_page.book_location,
            content_html: @old_page.content,
            spy: { ecosystem_title: @old_ecosystem.title }
          )
        end

        it 'returns the page with the correct uuid and version' do
          api_get page_api_ecosystem_path(@old_ecosystem.id, "#{@page_uuid}@2"), nil
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
