require 'rails_helper'

RSpec.describe Admin::BooksController do
  let!(:admin) { FactoryGirl.create :user_profile, :administrator }

  let!(:book_part_1) { FactoryGirl.create :content_book_part, title: 'Physics' }
  let!(:book_part_2) { FactoryGirl.create :content_book_part, title: 'AP Biology' }

  before { controller.sign_in(admin) }

  describe 'GET #index' do
    it 'lists books' do
      get :index

      expect(assigns[:books]).to eq([
        {
          'id' => book_part_2.entity_book_id,
          'title' => 'AP Biology',
          'uuid' => book_part_2.uuid,
          'version' => book_part_2.version,
          'url' => book_part_2.url
        },
        {
          'id' => book_part_1.entity_book_id,
          'title' => 'Physics',
          'uuid' => book_part_1.uuid,
          'version' => book_part_1.version,
          'url' => book_part_1.url
        }
      ])
    end
  end
end
