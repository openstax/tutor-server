require 'rails_helper'

RSpec.describe Research::Models::Study, type: :model do
  subject(:study) { FactoryBot.create :research_study }

  it { is_expected.to have_many(:survey_plans) }
  it { is_expected.to have_many(:study_courses) }
  it { is_expected.to have_many(:courses) }
  it { is_expected.to have_many(:cohorts) }

  it { is_expected.to validate_presence_of(:name) }

  it 'cannot have activate_at cleared after set' do

  end

  it 'cannot change activate_at once active' do


  end

  # it { is_expected.to belong_to(:ecosystem) }

  # it { is_expected.to have_many(:pages) }
  # it { is_expected.to have_many(:exercises) }

  # it { is_expected.to validate_presence_of(:title) }
  # it { is_expected.to validate_presence_of(:uuid) }
  # it { is_expected.to validate_presence_of(:version) }

  # it 'can create a manifest hash' do
  #   expect(book.manifest_hash).to eq(
  #     {
  #       archive_url: book.archive_url,
  #       cnx_id: book.cnx_id,
  #       reading_processing_instructions: book.reading_processing_instructions,
  #       exercise_ids: book.exercises.map(&:uid).sort
  #     }
  #   )
  # end
end
