require 'rails_helper'

RSpec.describe Content::GetPage, type: :routine do
  it 'returns the cnx page with chapter and section' do
    page = FactoryGirl.create(:content_page, chapter_section: [5, 1])
    result = Content::GetPage[id: page.id]

    expect(result.chapter_section).to eq([5, 1])
  end
end
