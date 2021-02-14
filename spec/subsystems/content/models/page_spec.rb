require 'rails_helper'
require 'vcr_helper'
require 'database_cleaner'

RSpec.describe Content::Models::Page, type: :model, vcr: VCR_OPTS do
  subject(:page) { FactoryBot.create :content_page }

  it { is_expected.to belong_to(:book) }

  it { is_expected.to validate_presence_of(:title) }

end
