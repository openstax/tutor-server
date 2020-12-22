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
      let!(:exercise2) do
        FactoryBot.build(
          :content_exercise, user_profile_id: 1, number: 2, content_page_id: exercise.page.id
        ).tap do |e|
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
      let!(:ecosystem) { page.ecosystem }
      let!(:new_eco_tag) { FactoryBot.create(:content_tag, value: 'test:tag', ecosystem: ecosystem) }

      it 'updates the page and tags to a new ecosystem' do
        old_page_id = exercise.page.id
        result = described_class.call(ecosystem: ecosystem, save: true).outputs
        exercise.reload
        unmapped.reload

        dup_exercise  = ecosystem.exercises.find_by(number: exercise.number)
        dup_exercise2 = ecosystem.exercises.find_by(number: exercise2.number)

        expect(result.updated_exercise_ids_by_page_id).to(
          eq({ old_page_id.to_s => [[exercise.id, dup_exercise.id], [exercise2.id, dup_exercise2.id]] })
        )
        expect(exercise.content_page_id).to eq(old_page_id)
        expect(dup_exercise.content_page_id).to eq(page.id)
        expect(dup_exercise.ecosystem).to eq(ecosystem)
        expect(unmapped.content_page_id).not_to eq(page.id)
        expect(dup_exercise.tags.map(&:ecosystem)).to include page.ecosystem
        expect(dup_exercise.tags).to include new_eco_tag
        expect(result.mapped_page_ids).to eq({ old_page_id.to_s => page.id })
      end

      it 'does nothing if no updated mappings are found' do
        exercise.update_column(:content_page_id, page.id)
        exercise2.update_column(:content_page_id, page.id)
        result = described_class.call(ecosystem: ecosystem, save: true).outputs
        expect(result.updated_exercise_ids_by_page_id).to be_empty
      end
    end
  end
end
