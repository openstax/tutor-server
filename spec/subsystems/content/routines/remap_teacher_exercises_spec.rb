require 'rails_helper'

RSpec.describe Content::Routines::RemapTeacherExercises, type: :routine do
  context 'with a teacher-created exercise' do
    context 'in an old ecosystem' do
      let!(:exercise) do
        FactoryBot.build(:content_exercise, user_profile_id: 1, number: 1).tap do |e|
          e.save(validate: false)
          e.tags << FactoryBot.create(:content_tag, value: 'test:tag')
        end
      end
      let!(:unmapped) do
        FactoryBot.build(:content_exercise, user_profile_id: 1, number: 1).tap do |e|
          e.save(validate: false)
        end
      end

      let!(:page) { FactoryBot.create :content_page, uuid: exercise.page.uuid }
      let(:ecosystem) { page.ecosystem }

      it 'updates the page and tags to a new ecosystem' do
        old_page_id = exercise.page.id
        result = described_class.call(ecosystem: ecosystem, save: true).outputs
        exercise.reload
        unmapped.reload

        expect(result.updated_exercise_ids_by_page_id).to eq({ old_page_id.to_s => [exercise.id] })
        expect(exercise.content_page_id).to eq(page.id)
        expect(unmapped.content_page_id).not_to eq(page.id)
        expect(exercise.tags.map(&:ecosystem)).to include page.ecosystem
      end
    end
  end
end
