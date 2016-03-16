require 'rails_helper'

RSpec.describe Settings::Exercises, type: :lib do
  it 'can store the excluded uids' do
    expect(described_class.excluded_uids).to eq ''

    described_class.excluded_uids = '1@1,2@1'
    Settings::Db.store.object('excluded_uids').expire_cache
    expect(described_class.excluded_uids).to eq '1@1,2@1'

    described_class.excluded_uids = ''
    Settings::Db.store.object('excluded_uids').expire_cache
    expect(described_class.excluded_uids).to eq ''
  end

  it 'can store the excluded pool uuid' do
    expect(described_class.excluded_pool_uuid).to eq ''

    uuid = SecureRandom.uuid
    described_class.excluded_pool_uuid = uuid
    Settings::Db.store.object('excluded_pool_uuid').expire_cache
    expect(described_class.excluded_pool_uuid).to eq uuid

    described_class.excluded_pool_uuid = ''
    Settings::Db.store.object('excluded_pool_uuid').expire_cache
    expect(described_class.excluded_pool_uuid).to eq ''
  end
end
