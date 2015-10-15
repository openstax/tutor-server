require 'rails_helper'

module Content
  module Strategies
    module Generated
      RSpec.describe Map do
        let!(:old_content_exercise)         { FactoryGirl.create :content_exercise }
        let!(:old_content_pool) do
          pool = old_content_exercise.page.all_exercises_pool
          pool.update_attribute(:content_exercise_ids, [old_content_exercise.id])
          pool
        end

        let!(:new_content_exercise)         { FactoryGirl.create :content_exercise }
        let!(:new_content_pool) do
          pool = old_content_exercise.page.all_exercises_pool
          pool.update_attribute(:content_exercise_ids, [new_content_exercise.id])
          pool
        end

        let!(:another_old_content_chapter)  {
          FactoryGirl.create :content_chapter, book: old_content_exercise.book
        }
        let!(:another_old_content_page)     {
          FactoryGirl.create :content_page, chapter: another_old_content_chapter
        }
        let!(:another_old_content_exercise) {
          FactoryGirl.create :content_exercise, page: another_old_content_page
        }
        let!(:another_old_content_page_2)   {
          FactoryGirl.create :content_page, chapter: old_content_exercise.chapter
        }
        let!(:another_old_content_pool) do
          pool = another_old_content_exercise.page.all_exercises_pool
          pool.update_attribute(:content_exercise_ids, [another_old_content_exercise.id])
          pool
        end

        let!(:another_new_content_chapter)  {
          FactoryGirl.create :content_chapter, book: new_content_exercise.book
        }
        let!(:another_new_content_page)     {
          FactoryGirl.create :content_page, chapter: another_new_content_chapter
        }
        let!(:another_new_content_exercise) {
          FactoryGirl.create :content_exercise, page: another_new_content_page
        }
        let!(:another_new_content_page_2)   {
          FactoryGirl.create :content_page, chapter: new_content_exercise.chapter
        }
        let!(:another_new_content_pool) do
          pool = another_new_content_exercise.page.all_exercises_pool
          pool.update_attribute(:content_exercise_ids, [another_new_content_exercise.id])
          pool
        end

        let!(:old_lo_tag)                   {
          FactoryGirl.create :content_tag, ecosystem: old_content_exercise.ecosystem,
                                           tag_type: :lo,
                                           value: 'lo01'
        }
        let!(:old_exercise_tag)             {
          FactoryGirl.create :content_exercise_tag, exercise: old_content_exercise,
                                                    tag: old_lo_tag
        }
        let!(:old_page_tag)                 {
          FactoryGirl.create :content_page_tag, page: old_content_exercise.page,
                                                tag: old_lo_tag
        }

        let!(:new_lo_tag)                   {
          FactoryGirl.create :content_tag, ecosystem: new_content_exercise.ecosystem,
                                           tag_type: :lo,
                                           value: 'lo01'
        }
        let!(:new_exercise_tag)             {
          FactoryGirl.create :content_exercise_tag, exercise: new_content_exercise,
                                                    tag: new_lo_tag
        }
        let!(:new_page_tag)                 {
          FactoryGirl.create :content_page_tag, page: new_content_exercise.page,
                                                tag: new_lo_tag
        }

        let!(:another_old_lo_tag)           {
          FactoryGirl.create :content_tag, ecosystem: old_content_exercise.ecosystem,
                                           tag_type: :lo,
                                           value: 'lo02'
        }
        let!(:another_old_exercise_tag)     {
          FactoryGirl.create :content_exercise_tag, exercise: another_old_content_exercise,
                                                    tag: another_old_lo_tag
        }
        let!(:another_old_page_tag)         {
          FactoryGirl.create :content_page_tag, page: another_old_content_exercise.page,
                                                tag: another_old_lo_tag
        }

        let!(:another_new_lo_tag)           {
          FactoryGirl.create :content_tag, ecosystem: new_content_exercise.ecosystem,
                                           tag_type: :lo,
                                           value: 'lo02'
        }
        let!(:another_new_exercise_tag)     {
          FactoryGirl.create :content_exercise_tag, exercise: another_new_content_exercise,
                                                    tag: another_new_lo_tag
        }
        let!(:another_new_page_tag)         {
          FactoryGirl.create :content_page_tag, page: another_new_content_exercise.page,
                                                tag: another_new_lo_tag
        }

        let!(:old_exercise)                 do
          model = old_content_exercise
          strategy = ::Content::Strategies::Direct::Exercise.new(model)
          ::Content::Exercise.new(strategy: strategy)
        end
        let!(:new_exercise)                 do
          model = new_content_exercise
          strategy = ::Content::Strategies::Direct::Exercise.new(model)
          ::Content::Exercise.new(strategy: strategy)
        end

        let!(:old_page)                     { old_exercise.page }
        let!(:new_page)                     { new_exercise.page }

        let!(:old_pool)                     {  }

        let!(:old_ecosystem)                { old_page.chapter.book.ecosystem }
        let!(:new_ecosystem)                { new_page.chapter.book.ecosystem }

        let!(:another_old_exercise)                 do
          model = another_old_content_exercise
          strategy = ::Content::Strategies::Direct::Exercise.new(model)
          ::Content::Exercise.new(strategy: strategy)
        end
        let!(:another_new_exercise)                 do
          model = another_new_content_exercise
          strategy = ::Content::Strategies::Direct::Exercise.new(model)
          ::Content::Exercise.new(strategy: strategy)
        end

        let!(:another_old_page)             { another_old_exercise.page }
        let!(:another_new_page)             { another_new_exercise.page }

        subject(:map)                       {
          Content::Map.create!(from_ecosystems: [old_ecosystem, new_ecosystem],
                               to_ecosystem: new_ecosystem,
                               strategy_class: described_class)
        }

        it 'can map from_ecosystems exercises to to_ecosystem pages' do
          mapping = map.map_exercises_to_pages(exercises: [
            old_exercise, new_exercise
          ])
          [old_exercise, new_exercise].each do |exercise|
            expect(mapping[exercise.id]).to eq new_page
          end

          mapping_2 = map.map_exercises_to_pages(exercises: [
            another_old_exercise, another_new_exercise
          ])
          [another_old_exercise, another_new_exercise].each do |exercise|
            expect(mapping_2[exercise.id]).to eq another_new_page
          end

          # Try again to see that we get the same results with the cached mapping
          mapping_3 = map.map_exercises_to_pages(exercises: [
            old_exercise, new_exercise, another_old_exercise, another_new_exercise
          ])
          [old_exercise, new_exercise].each do |exercise|
            expect(mapping_3[exercise.id]).to eq new_page
          end

          [another_old_exercise, another_new_exercise].each do |exercise|
            expect(mapping_3[exercise.id]).to eq another_new_page
          end
        end

        it 'can map from_ecosystems pages to to_ecosystem exercises' do
          mapping = map.map_pages_to_exercises(pages: [
            old_page, new_page
          ])
          [old_page, new_page].each do |page|
            expect(mapping[page.id]).to eq [new_exercise]
          end

          mapping_2 = map.map_pages_to_exercises(pages: [
            another_old_page, another_new_page
          ])
          [another_old_page, another_new_page].each do |page|
            expect(mapping_2[page.id]).to eq [another_new_exercise]
          end

          # Try again to see that we get the same results with the cached mapping
          mapping_3 = map.map_pages_to_exercises(pages: [
            old_page, new_page, another_old_page, another_new_page
          ])
          [old_page, new_page].each do |page|
            expect(mapping_3[page.id]).to eq [new_exercise]
          end

          [another_old_page, another_new_page].each do |page|
            expect(mapping_3[page.id]).to eq [another_new_exercise]
          end
        end

        it 'does not return exercises in other pools' do
          mapping = map.map_pages_to_exercises(pages: [
            old_page, new_page
          ], pool_type: :practice_widget)
          [old_page, new_page].each do |page|
            expect(mapping[page.id]).to eq []
          end

          mapping_2 = map.map_pages_to_exercises(pages: [
            another_old_page, another_new_page
          ], pool_type: :practice_widget)
          [another_old_page, another_new_page].each do |page|
            expect(mapping_2[page.id]).to eq []
          end
        end

        it 'knows if it is valid or not' do
          # The ecosystems are identical, so we can map both ways
          expect(map).to be_valid
          reverse_map = Content::Map.create!(from_ecosystems: [old_ecosystem, new_ecosystem],
                                             to_ecosystem: old_ecosystem,
                                             strategy_class: described_class)
          expect(reverse_map).to be_valid

          # Pretend lo02 and its page were added only in the new ecosystem
          another_old_lo_tag.exercises.first.destroy
          another_old_lo_tag.pages.first.destroy
          another_old_lo_tag.destroy

          # Rewrap the old ecosystem so we pick up the changes
          modified_old_strategy = Content::Strategies::Direct::Ecosystem.new(
            another_old_lo_tag.ecosystem
          )
          modified_old_ecosystem = Content::Ecosystem.new(strategy: modified_old_strategy)

          # We can still map forward, but the reverse map is now invalid
          modified_map = Content::Map.create!(
            from_ecosystems: [modified_old_ecosystem, new_ecosystem],
            to_ecosystem: new_ecosystem,
            strategy_class: described_class
          )
          expect(modified_map).to be_valid
          reverse_modified_map = Content::Map.create(
            from_ecosystems: [modified_old_ecosystem, new_ecosystem],
            to_ecosystem: modified_old_ecosystem,
            strategy_class: described_class
          )
          expect(reverse_modified_map).not_to be_valid
        end
      end
    end
  end
end
