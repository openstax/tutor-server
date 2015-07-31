require 'rails_helper'
require 'vcr_helper'

RSpec.describe Admin::BooksController, speed: :slow, vcr: VCR_OPTS do
  let!(:admin) { FactoryGirl.create :user_profile, :administrator }

  let!(:book_part_1) { FactoryGirl.create :content_book_part, title: 'Physics' }
  let!(:book_part_2) { FactoryGirl.create :content_book_part, title: 'AP Biology' }

  before { controller.sign_in(admin) }

  describe 'GET #index' do
    it 'lists books' do
      get :index

      expect(assigns[:books]).to eq([
        {
          'id' => book_part_2.content_book_id,
          'title' => 'AP Biology',
          'uuid' => book_part_2.uuid,
          'version' => book_part_2.version,
          'url' => book_part_2.url,
          'title_with_id' => "AP Biology (#{book_part_2.uuid}@#{book_part_2.version})"
        },
        {
          'id' => book_part_1.content_book_id,
          'title' => 'Physics',
          'uuid' => book_part_1.uuid,
          'version' => book_part_1.version,
          'url' => book_part_1.url,
          'title_with_id' => "Physics (#{book_part_1.uuid}@#{book_part_1.version})"
        }
      ])
    end
  end

  describe 'POST #import' do
    let!(:archive_url) { 'https://archive-staging-tutor.cnx.org/contents/' }
    let!(:cnx_id) { '93e2b09d-261c-4007-a987-0b3062fe154b@4.4' }

    it 'imports books' do
      expect {
        post :import, archive_url: archive_url,
                      cnx_id: cnx_id
      }.to change { Content::Models::Book.count }.by(1)
      expect(flash[:notice]).to eq 'Book "Physics" imported.'
    end

    it 'does not import book if the book already exists' do
      FactoryGirl.create(:content_book_part,
                         title: 'Physics',
                         url: "#{archive_url}#{cnx_id}")

      expect {
        post :import, archive_url: archive_url,
                      cnx_id: cnx_id
      }.not_to change { Content::Models::Book.count }
      expect(flash[:error]).to eq 'Book "Physics" already imported.'
    end

    it 'imports a book with a different version' do
      FactoryGirl.create(:content_book_part,
                         title: 'Physics',
                         url: "#{archive_url}#{cnx_id}")

      expect {
        post :import, archive_url: archive_url,
                      cnx_id: cnx_id.sub('@4.4', '@4.3')
      }.to change { Content::Models::Book.count }.by(1)
      expect(flash[:notice]).to eq 'Book "Physics" imported.'
    end
  end
end
