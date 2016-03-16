require 'rails_helper'

RSpec.describe Settings::Salesforce, type: :lib do
  it 'can store import_real_salesforce_courses' do
    expect(described_class.import_real_salesforce_courses).to eq false

    described_class.import_real_salesforce_courses = true
    Settings::Db.store.object('import_real_salesforce_courses').expire_cache
    expect(described_class.import_real_salesforce_courses).to eq true

    described_class.import_real_salesforce_courses = false
    Settings::Db.store.object('import_real_salesforce_courses').expire_cache
    expect(described_class.import_real_salesforce_courses).to eq false
  end
end
