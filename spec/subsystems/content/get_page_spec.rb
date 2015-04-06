require 'rails_helper'

RSpec.describe Content::GetPage do
  it 'returns the cnx page with a path' do
    page = FactoryGirl.create(:content_page, path: '5.1')
    result = Content::GetPage[id: page.id]

    expect(result.path).to eq('5.1')
  end
end
