require 'rails_helper'

RSpec.describe Content::Strategies::Generated::Map do
  let(:old_content_exercise)         { FactoryBot.create :content_exercise }
  let!(:old_content_pool) do
    pool = old_content_exercise.page.all_exercises_pool
    pool.update_attribute(:content_exercise_ids, [old_content_exercise.id])
    pool
  end

  let(:new_content_exercise)         { FactoryBot.create :content_exercise }
  let!(:new_content_pool) do
    pool = new_content_exercise.page.all_exercises_pool
    pool.update_attribute(:content_exercise_ids, [new_content_exercise.id])
    pool
  end

  let(:another_old_content_chapter)  {
    FactoryBot.create :content_chapter, book: old_content_exercise.book
  }
  let!(:another_old_content_page)    {
    FactoryBot.create :content_page, chapter: another_old_content_chapter
  }
  let(:another_old_content_exercise) {
    FactoryBot.create :content_exercise, page: another_old_content_page
  }
  let!(:another_old_content_page_2)  {
    FactoryBot.create :content_page, chapter: old_content_exercise.chapter
  }
  let!(:another_old_content_pool) do
    pool = another_old_content_exercise.page.all_exercises_pool
    pool.update_attribute(:content_exercise_ids, [another_old_content_exercise.id])
    pool
  end

  let(:another_new_content_chapter)  {
    FactoryBot.create :content_chapter, book: new_content_exercise.book
  }
  let!(:another_new_content_page)    {
    FactoryBot.create :content_page, chapter: another_new_content_chapter
  }
  let(:another_new_content_exercise) {
    FactoryBot.create :content_exercise, page: another_new_content_page
  }
  let!(:another_new_content_page_2)  {
    FactoryBot.create :content_page, chapter: new_content_exercise.chapter
  }
  let!(:another_new_content_pool) do
    pool = another_new_content_exercise.page.all_exercises_pool
    pool.update_attribute(:content_exercise_ids, [another_new_content_exercise.id])
    pool
  end

  let!(:old_lo_tag)                  {
    FactoryBot.create :content_tag, ecosystem: old_content_exercise.ecosystem,
                                     tag_type: :lo,
                                     value: 'lo01'
  }
  let!(:old_exercise_tag)            {
    FactoryBot.create :content_exercise_tag, exercise: old_content_exercise,
                                              tag: old_lo_tag
  }
  let!(:old_page_tag)                {
    FactoryBot.create :content_page_tag, page: old_content_exercise.page,
                                          tag: old_lo_tag
  }

  let!(:new_lo_tag)                  {
    FactoryBot.create :content_tag, ecosystem: new_content_exercise.ecosystem,
                                     tag_type: :lo,
                                     value: 'lo01'
  }
  let!(:new_exercise_tag)            {
    FactoryBot.create :content_exercise_tag, exercise: new_content_exercise,
                                              tag: new_lo_tag
  }
  let!(:new_page_tag)                {
    FactoryBot.create :content_page_tag, page: new_content_exercise.page,
                                          tag: new_lo_tag
  }

  let!(:another_old_lo_tag)          {
    FactoryBot.create :content_tag, ecosystem: old_content_exercise.ecosystem,
                                     tag_type: :lo,
                                     value: 'lo02'
  }
  let!(:another_old_exercise_tag)    {
    FactoryBot.create :content_exercise_tag, exercise: another_old_content_exercise,
                                              tag: another_old_lo_tag
  }
  let!(:another_old_page_tag)        {
    FactoryBot.create :content_page_tag, page: another_old_content_exercise.page,
                                          tag: another_old_lo_tag
  }

  let!(:another_new_lo_tag)          {
    FactoryBot.create :content_tag, ecosystem: new_content_exercise.ecosystem,
                                     tag_type: :lo,
                                     value: 'lo02'
  }
  let!(:another_new_exercise_tag)    {
    FactoryBot.create :content_exercise_tag, exercise: another_new_content_exercise,
                                              tag: another_new_lo_tag
  }
  let!(:another_new_page_tag)        {
    FactoryBot.create :content_page_tag, page: another_new_content_exercise.page,
                                          tag: another_new_lo_tag
  }

  let(:old_exercise)                 do
    model = old_content_exercise
    strategy = ::Content::Strategies::Direct::Exercise.new(model)
    ::Content::Exercise.new(strategy: strategy)
  end
  let(:new_exercise)                 do
    model = new_content_exercise
    strategy = ::Content::Strategies::Direct::Exercise.new(model)
    ::Content::Exercise.new(strategy: strategy)
  end

  let(:old_page)                     { old_exercise.page }
  let(:new_page)                     { new_exercise.page }

  let(:old_ecosystem)                { old_page.chapter.book.ecosystem }
  let(:new_ecosystem)                { new_page.chapter.book.ecosystem }

  let(:another_old_exercise)                 do
    model = another_old_content_exercise
    strategy = ::Content::Strategies::Direct::Exercise.new(model)
    ::Content::Exercise.new(strategy: strategy)
  end
  let(:another_new_exercise)                 do
    model = another_new_content_exercise
    strategy = ::Content::Strategies::Direct::Exercise.new(model)
    ::Content::Exercise.new(strategy: strategy)
  end

  let(:another_old_page)             { another_old_exercise.page }
  let(:another_new_page)             { another_new_exercise.page }

  subject(:map)                      do
    Content::Map.find_or_create_by!(from_ecosystems: [old_ecosystem, new_ecosystem],
                                    to_ecosystem: new_ecosystem,
                                    strategy_class: described_class)
  end

  it 'can map from_ecosystems exercises to to_ecosystem pages' do
    mapping = map.map_exercises_to_pages(exercises: [old_exercise, new_exercise])
    [old_exercise, new_exercise].each do |exercise|
      expect(mapping[exercise]).to eq new_page
    end

    mapping_2 = map.map_exercises_to_pages(exercises: [another_old_exercise, another_new_exercise])
    [another_old_exercise, another_new_exercise].each do |exercise|
      expect(mapping_2[exercise]).to eq another_new_page
    end

    # Try again to see that we get the same results with the cached mapping
    mapping_3 = map.map_exercises_to_pages(exercises: [
      old_exercise, new_exercise, another_old_exercise, another_new_exercise
    ])
    [old_exercise, new_exercise].each do |exercise|
      expect(mapping_3[exercise]).to eq new_page
    end

    [another_old_exercise, another_new_exercise].each do |exercise|
      expect(mapping_3[exercise]).to eq another_new_page
    end
  end

  it 'can map from_ecosystems pages to to_ecosystem pages' do
    mapping = map.map_pages_to_pages(pages: [old_page, new_page])
    [old_page, new_page].each do |page|
      expect(mapping[page]).to eq new_page
    end

    mapping_2 = map.map_pages_to_pages(pages: [another_old_page, another_new_page])
    [another_old_page, another_new_page].each do |page|
      expect(mapping_2[page]).to eq another_new_page
    end

    # Try again to see that we get the same results with the cached mapping
    mapping_3 = map.map_pages_to_pages(pages: [
      old_page, new_page, another_old_page, another_new_page
    ])
    [old_page, new_page].each do |page|
      expect(mapping_3[page]).to eq new_page
    end

    [another_old_page, another_new_page].each do |page|
      expect(mapping_3[page]).to eq another_new_page
    end
  end

  it 'can map from_ecosystems pages to to_ecosystem exercises' do
    mapping = map.map_pages_to_exercises(pages: [old_page, new_page])
    [old_page, new_page].each do |page|
      expect(mapping[page]).to eq [new_exercise]
    end

    mapping_2 = map.map_pages_to_exercises(pages: [another_old_page, another_new_page])
    [another_old_page, another_new_page].each do |page|
      expect(mapping_2[page]).to eq [another_new_exercise]
    end

    # Try again to see that we get the same results with the cached mapping
    mapping_3 = map.map_pages_to_exercises(pages: [
      old_page, new_page, another_old_page, another_new_page
    ])
    [old_page, new_page].each do |page|
      expect(mapping_3[page]).to eq [new_exercise]
    end

    [another_old_page, another_new_page].each do |page|
      expect(mapping_3[page]).to eq [another_new_exercise]
    end
  end

  it 'does not return exercises in other pools' do
    mapping = map.map_pages_to_exercises(pages: [old_page, new_page], pool_type: :practice_widget)
    [old_page, new_page].each do |page|
      expect(mapping[page]).to eq []
    end

    mapping_2 = map.map_pages_to_exercises(pages: [
      another_old_page, another_new_page
    ], pool_type: :practice_widget)
    [another_old_page, another_new_page].each do |page|
      expect(mapping_2[page]).to eq []
    end
  end

  it 'knows if it is valid or not' do
    # The ecosystems are identical, so we can map both ways
    expect(map.is_valid).to eq true
    reverse_map = Content::Map.find_or_create_by!(from_ecosystems: [old_ecosystem, new_ecosystem],
                                                  to_ecosystem: old_ecosystem,
                                                  strategy_class: described_class)
    expect(reverse_map.is_valid).to eq true

    # Pretend lo02 and its page were added only in the new ecosystem
    Content::Models::Exercise.where(id: another_old_lo_tag.exercises.map(&:id)).delete_all
    Content::Models::Page.where(id: another_old_lo_tag.pages.map(&:id)).delete_all
    Content::Models::Tag.where(id: another_old_lo_tag.id).delete_all

    # Rewrap the old ecosystem so we pick up the changes properly
    modified_old_strategy = another_old_lo_tag.ecosystem.reload.wrap
    modified_old_ecosystem = Content::Ecosystem.new(strategy: modified_old_strategy)

    # The map validity is cached, so it is still valid
    modified_map = Content::Map.find_or_create_by!(
      from_ecosystems: [modified_old_ecosystem, new_ecosystem],
      to_ecosystem: new_ecosystem,
      strategy_class: described_class
    )
    expect(modified_map.is_valid).to eq true
    reverse_modified_map = Content::Map.find_or_create_by!(
      from_ecosystems: [modified_old_ecosystem, new_ecosystem],
      to_ecosystem: modified_old_ecosystem,
      strategy_class: described_class
    )
    expect(reverse_modified_map.is_valid).to eq true

    # Clear the map cache
    Content::Models::Map.delete_all

    # We can still map forward, but the reverse map is now invalid
    modified_map = Content::Map.find_or_create_by!(
      from_ecosystems: [modified_old_ecosystem, new_ecosystem],
      to_ecosystem: new_ecosystem,
      strategy_class: described_class
    )
    expect(modified_map.is_valid).to eq true
    reverse_modified_map = Content::Map.find_or_create_by(
      from_ecosystems: [modified_old_ecosystem, new_ecosystem],
      to_ecosystem: modified_old_ecosystem,
      strategy_class: described_class
    )
    expect(reverse_modified_map.is_valid).to eq false
  end

  it 'outputs diagnostics when mapping fails' do
    # Create an invalid ecosystem mapping
    Content::Models::Exercise.where(id: another_old_lo_tag.exercises.map(&:id)).delete_all
    Content::Models::Page.where(id: another_old_lo_tag.pages.map(&:id)).delete_all
    Content::Models::Tag.where(id: another_old_lo_tag.id).delete_all

    # Rewrap the old ecosystem so we pick up the changes properly
    modified_old_strategy = another_old_lo_tag.ecosystem.reload.wrap
    modified_old_ecosystem = Content::Ecosystem.new(strategy: modified_old_strategy)

    expect{
      Content::Map.find_or_create_by!(
        from_ecosystems: [modified_old_ecosystem, new_ecosystem],
        to_ecosystem: modified_old_ecosystem,
        strategy_class: described_class
      )
    }.to raise_error(Content::MapInvalidError, /\AInvalid mapping/)
  end
end
