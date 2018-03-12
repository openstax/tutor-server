require 'rails_helper'

RSpec.describe Catalog::Models::Offering, type: :model do
  subject(:offering) { FactoryBot.create :catalog_offering }

  it { is_expected.to belong_to(:ecosystem) }

  it { is_expected.to have_many(:courses) }

  it { is_expected.to validate_presence_of(:salesforce_book_name) }
  it { is_expected.to validate_presence_of(:webview_url) }
  it { is_expected.to validate_presence_of(:title) }
  it { is_expected.to validate_presence_of(:description) }
  it { is_expected.to validate_presence_of(:ecosystem) }

  it 'knows if it is deletable' do
    preloaded_offering = described_class.preload_deletable.find_by(id: offering.id)
    expect(offering).to be_deletable
    expect(preloaded_offering).to be_deletable

    course = FactoryBot.create :course_profile_course, offering: offering
    expect(offering).not_to be_deletable
    expect(preloaded_offering).to be_deletable
    preloaded_offering = described_class.preload_deletable.find_by(id: offering.id)
    expect(preloaded_offering).not_to be_deletable

    course.really_destroy!
    expect(offering).to be_deletable
    expect(preloaded_offering).not_to be_deletable
    preloaded_offering = described_class.preload_deletable.find_by(id: offering.id)
    expect(preloaded_offering).to be_deletable
  end

  it 'refuses to be deleted if there are courses that use it' do
    course = FactoryBot.create :course_profile_course, offering: offering
    expect(offering).not_to be_deletable
    expect { offering.destroy }.not_to change { described_class.count }
    expect { offering.reload }.not_to raise_error

    course.really_destroy!
    expect(offering).to be_deletable
    expect { offering.destroy }.to change { described_class.count }.by(-1)
    expect { offering.reload }.to raise_error(ActiveRecord::RecordNotFound)
  end
end
