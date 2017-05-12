require 'rails_helper'

RSpec.describe Settings::Exercises, type: :lib do
  it 'can store the excluded_ids' do
    expect(described_class.excluded_ids).to eq ''

    described_class.excluded_ids = '1@1,2@1'
    Settings::Db.store.object('excluded_ids').expire_cache
    expect(described_class.excluded_ids).to eq '1@1,2@1'

    described_class.excluded_ids = ''
    Settings::Db.store.object('excluded_ids').expire_cache
    expect(described_class.excluded_ids).to eq ''
  end
end
