require 'rails_helper'

RSpec.describe Content::Routines::PopulateExercisePools, type: :routine do

  let(:page)                 { FactoryGirl.create :content_page }
  let(:book)                 { page.book }
  let(:ecosystem)            { book.ecosystem }

  let(:requires_context_tag) { FactoryGirl.create :content_tag, value: 'requires-context:true',
                                                                 tag_type: :requires_context,
                                                                 ecosystem: ecosystem }

  let(:exercise_1)           { FactoryGirl.create :content_exercise, page: page }
  let(:exercise_2)           { FactoryGirl.create :content_exercise, page: page }
  let(:exercise_3)           { FactoryGirl.create :content_exercise, page: page, num_parts: 2 }

  let!(:exercise_2_tag)      { FactoryGirl.create :content_exercise_tag,
                                                  exercise: exercise_2, tag: requires_context_tag }

  let(:all_exercises_set)    { Set[exercise_1, exercise_2, exercise_3] }

  before { page.exercises += all_exercises_set.to_a }

  context 'hs book' do
    before{ book.update_attribute :uuid, '93e2b09d-261c-4007-a987-0b3062fe154b' }

    it 'imports any exercise into the practice widget pool' do
      described_class.call(book: book)

      expect(Set.new page.reload.practice_widget_pool.exercises).to eq all_exercises_set
      expect(Set.new page.all_exercises_pool.exercises).to eq all_exercises_set
    end
  end

  context 'cc book' do
    it "imports simple exercises that don't require context into the practice widget pool" do
      described_class.call(book: book)

      expect(page.reload.practice_widget_pool.exercises).to eq [exercise_1]
      expect(Set.new page.all_exercises_pool.exercises).to eq all_exercises_set
    end
  end

end
