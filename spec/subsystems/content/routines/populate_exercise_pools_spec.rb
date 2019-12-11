require 'rails_helper'

RSpec.describe Content::Routines::PopulateExercisePools, type: :routine do
  let(:page)                 { FactoryBot.create :content_page }
  let(:book)                 { page.book }
  let(:ecosystem)            { book.ecosystem }

  let(:k12phys_tag)          { FactoryBot.create :content_tag, value: 'k12phys',
                                                                ecosystem: ecosystem }
  let(:apbio_tag)            { FactoryBot.create :content_tag, value: 'apbio',
                                                                ecosystem: ecosystem }

  let(:os_prac_conc_tag)     { FactoryBot.create :content_tag, value: 'os-practice-concepts',
                                                                ecosystem: ecosystem }
  let(:os_prac_prob_tag)     { FactoryBot.create :content_tag, value: 'os-practice-problems',
                                                                ecosystem: ecosystem }

  let(:chapter_review_tag)   { FactoryBot.create :content_tag, value: 'ost-chapter-review',
                                                                ecosystem: ecosystem }

  let(:type_conceptual_tag)  { FactoryBot.create :content_tag, value: 'type:conceptual',
                                                                ecosystem: ecosystem }
  let(:type_recall_tag)      { FactoryBot.create :content_tag, value: 'type:recall',
                                                                ecosystem: ecosystem }
  let(:type_conc_recall_tag) { FactoryBot.create :content_tag, value: 'type:conceptual-or-recall',
                                                                ecosystem: ecosystem }
  let(:type_practice_tag)    { FactoryBot.create :content_tag, value: 'type:practice',
                                                                ecosystem: ecosystem }

  let(:review_tag)           { FactoryBot.create :content_tag, value: 'review',
                                                                ecosystem: ecosystem }
  let(:concept_tag)          { FactoryBot.create :content_tag, value: 'concept',
                                                                ecosystem: ecosystem }
  let(:problem_tag)          { FactoryBot.create :content_tag, value: 'problem',
                                                                ecosystem: ecosystem }
  let(:crit_think_tag)       { FactoryBot.create :content_tag, value: 'critical-thinking',
                                                                ecosystem: ecosystem }
  let(:ap_test_prep_tag)     { FactoryBot.create :content_tag, value: 'ap-test-prep',
                                                                ecosystem: ecosystem }

  let(:time_short_tag)       { FactoryBot.create :content_tag, value: 'time:short',
                                                                ecosystem: ecosystem }
  let(:time_medium_tag)      { FactoryBot.create :content_tag, value: 'time:medium',
                                                                ecosystem: ecosystem }
  let(:time_long_tag)        { FactoryBot.create :content_tag, value: 'time:long',
                                                                ecosystem: ecosystem }

  let(:requires_context_tag) { FactoryBot.create :content_tag, value: 'requires-context:true',
                                                                tag_type: :requires_context,
                                                                ecosystem: ecosystem }

  let(:concept_coach_tag)    { FactoryBot.create :content_tag, value: 'ost-type:concept-coach',
                                                                ecosystem: ecosystem }

  let(:untagged_exercise)         { FactoryBot.create :content_exercise, page: page }

  let(:k12phys_read_dyn_exercise) { FactoryBot.create :content_exercise, page: page }
  let(:apbio_read_dyn_exercise)   { FactoryBot.create :content_exercise, page: page }

  let(:k12phys_hw_dyn_exercise_1) { FactoryBot.create :content_exercise, page: page }
  let(:k12phys_hw_dyn_exercise_2) { FactoryBot.create :content_exercise, page: page }
  let(:k12phys_hw_dyn_exercise_3) { FactoryBot.create :content_exercise, page: page }
  let(:k12phys_hw_dyn_exercise_4) { FactoryBot.create :content_exercise, page: page }
  let(:apbio_hw_dyn_exercise_1)   { FactoryBot.create :content_exercise, page: page }
  let(:apbio_hw_dyn_exercise_2)   { FactoryBot.create :content_exercise, page: page }
  let(:apbio_hw_dyn_exercise_3)   { FactoryBot.create :content_exercise, page: page }
  let(:apbio_hw_dyn_exercise_4)   { FactoryBot.create :content_exercise, page: page }

  let(:prac_prob_exercise)        { FactoryBot.create :content_exercise, page: page }
  let(:chapter_review_exercise)   { FactoryBot.create :content_exercise, page: page }

  let(:conceptual_exercise)       { FactoryBot.create :content_exercise, page: page }
  let(:recall_exercise)           { FactoryBot.create :content_exercise, page: page }
  let(:conc_recall_exercise)      { FactoryBot.create :content_exercise, page: page }
  let(:practice_exercise)         { FactoryBot.create :content_exercise, page: page }

  let(:requires_context_exercise) { FactoryBot.create :content_exercise, page: page }

  let(:concept_coach_exercise)    { FactoryBot.create :content_exercise, page: page }

  let(:untagged_multi_exercise)   do
    FactoryBot.create :content_exercise, page: page, num_questions: 2
  end

  let(:conc_multi_exercise)       do
    FactoryBot.create :content_exercise, page: page, num_questions: 2
  end
  let(:recall_multi_exercise)     do
    FactoryBot.create :content_exercise, page: page, num_questions: 2
  end
  let(:c_or_r_multi_exercise)     do
    FactoryBot.create :content_exercise, page: page, num_questions: 2
  end
  let(:practice_multi_exercise)   do
    FactoryBot.create :content_exercise, page: page, num_questions: 2
  end

  let(:cc_multi_exercise)         do
    FactoryBot.create :content_exercise, page: page, num_questions: 2
  end

  let(:exercise_tags) do
    {
      untagged_exercise         => [],
      k12phys_read_dyn_exercise => [k12phys_tag, os_prac_conc_tag],
      apbio_read_dyn_exercise   => [apbio_tag, chapter_review_tag, review_tag, time_short_tag],
      k12phys_hw_dyn_exercise_1 => [k12phys_tag, os_prac_prob_tag],
      k12phys_hw_dyn_exercise_2 => [k12phys_tag, chapter_review_tag, concept_tag],
      k12phys_hw_dyn_exercise_3 => [k12phys_tag, chapter_review_tag, problem_tag],
      k12phys_hw_dyn_exercise_4 => [k12phys_tag, chapter_review_tag, crit_think_tag],
      apbio_hw_dyn_exercise_1   => [apbio_tag, chapter_review_tag, crit_think_tag],
      apbio_hw_dyn_exercise_2   => [apbio_tag, chapter_review_tag, ap_test_prep_tag],
      apbio_hw_dyn_exercise_3   => [apbio_tag, chapter_review_tag, review_tag, time_medium_tag],
      apbio_hw_dyn_exercise_4   => [apbio_tag, chapter_review_tag, review_tag, time_long_tag],
      prac_prob_exercise        => [os_prac_prob_tag],
      chapter_review_exercise   => [chapter_review_tag],
      conceptual_exercise       => [type_conceptual_tag],
      recall_exercise           => [type_recall_tag],
      conc_recall_exercise      => [type_conc_recall_tag],
      practice_exercise         => [type_practice_tag],
      requires_context_exercise => [requires_context_tag],
      concept_coach_exercise    => [concept_coach_tag],
      untagged_multi_exercise   => [],
      conc_multi_exercise       => [type_conceptual_tag],
      recall_multi_exercise     => [type_recall_tag],
      c_or_r_multi_exercise     => [type_conc_recall_tag],
      practice_multi_exercise   => [type_practice_tag],
      cc_multi_exercise         => [concept_coach_tag]
    }
  end

  let(:all_exercises)           { exercise_tags.keys }
  let(:all_exercise_ids_set)    { Set.new all_exercises.map(&:id) }
  let(:simple_exercise_ids_set) { Set.new all_exercises.reject(&:is_multipart?).map(&:id) }

  before do
    exercise_tags.each { |exercise, tags| exercise.tags = tags }

    page.exercises = all_exercises.to_a
  end

  context 'all books' do
    before do
      described_class.call book: book

      page.reload
    end

    it "imports simple exercises that don't require context into the practice widget pool" do
      expect(Set.new page.practice_widget_exercise_ids).to eq(
        simple_exercise_ids_set - [requires_context_exercise.id]
      )
    end

    it 'imports simple recall, conceptual and c-or-r exercises into the reading dynamic pool' do
      expect(Set.new page.reading_dynamic_exercise_ids).to eq Set[
        conceptual_exercise.id,
        recall_exercise.id,
        conc_recall_exercise.id
      ]
    end

    it 'imports all simple exercises into the reading context pool' do
      expect(Set.new page.reading_context_exercise_ids).to eq simple_exercise_ids_set
    end

    it 'imports practice exercises into the homework core pool' do
      expect(Set.new page.homework_core_exercise_ids).to eq Set[
        practice_exercise.id,
        practice_multi_exercise.id
      ]
    end

    it 'imports simple practice exercises into the homework dynamic pool' do
      expect(page.homework_dynamic_exercise_ids).to eq [
        practice_exercise.id
      ]
    end
  end
end
