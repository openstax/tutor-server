require 'rails_helper'

RSpec.describe Content::Map, speed: :medium do
  let!(:old_exercise)             do
    FactoryBot.create(:content_exercise).tap do |exercise|
      exercise.page.update_attribute(:homework_core_exercise_ids, [ exercise.id ])
    end
  end

  let!(:new_exercise)             do
    FactoryBot.create(:content_exercise).tap do |exercise|
      exercise.page.update_attribute(:homework_core_exercise_ids, [ exercise.id ])
    end
  end

  let!(:another_old_page)         { FactoryBot.create :content_page, book: old_exercise.book }
  let!(:another_old_exercise)     do
    FactoryBot.create(:content_exercise, page: another_old_page).tap do |exercise|
      exercise.page.update_attribute(:homework_core_exercise_ids, [ exercise.id ])
    end
  end
  let!(:another_old_page_2)       { FactoryBot.create :content_page, book: old_exercise.book }

  let!(:another_new_page)         { FactoryBot.create :content_page, book: new_exercise.book }
  let!(:another_new_exercise)     do
    FactoryBot.create(:content_exercise, page: another_new_page).tap do |exercise|
      exercise.page.update_attribute(:homework_core_exercise_ids, [ exercise.id ])
    end
  end
  let!(:another_new_page_2)       { FactoryBot.create :content_page, book: new_exercise.book }

  let!(:old_lo_tag)               do
    FactoryBot.create :content_tag, ecosystem: old_exercise.ecosystem, tag_type: :lo, value: 'lo01'
  end
  let!(:old_exercise_tag)         do
    FactoryBot.create :content_exercise_tag, exercise: old_exercise, tag: old_lo_tag
  end
  let!(:old_page_tag)             do
    FactoryBot.create :content_page_tag, page: old_exercise.page, tag: old_lo_tag
  end

  let!(:new_lo_tag)               do
    FactoryBot.create :content_tag, ecosystem: new_exercise.ecosystem, tag_type: :lo, value: 'lo01'
  end
  let!(:new_exercise_tag)         do
    FactoryBot.create :content_exercise_tag, exercise: new_exercise, tag: new_lo_tag
  end
  let!(:new_page_tag)             do
    FactoryBot.create :content_page_tag, page: new_exercise.page, tag: new_lo_tag
  end

  let!(:another_old_lo_tag)       do
    FactoryBot.create :content_tag, ecosystem: old_exercise.ecosystem, tag_type: :lo, value: 'lo02'
  end
  let!(:another_old_exercise_tag) do
    FactoryBot.create :content_exercise_tag, exercise: another_old_exercise, tag: another_old_lo_tag
  end
  let!(:another_old_page_tag)     do
    FactoryBot.create :content_page_tag, page: another_old_exercise.page, tag: another_old_lo_tag
  end

  let!(:another_new_lo_tag)       do
    FactoryBot.create :content_tag, ecosystem: new_exercise.ecosystem, tag_type: :lo, value: 'lo02'
  end
  let!(:another_new_exercise_tag) do
    FactoryBot.create :content_exercise_tag, exercise: another_new_exercise, tag: another_new_lo_tag
  end
  let!(:another_new_page_tag)     do
    FactoryBot.create :content_page_tag, page: another_new_exercise.page, tag: another_new_lo_tag
  end

  let(:old_page)                  { old_exercise.page }
  let(:new_page)                  { new_exercise.page }

  let(:old_ecosystem)             { old_page.book.ecosystem.reload }
  let(:new_ecosystem)             { new_page.book.ecosystem.reload }

  subject(:map)                   do
    Content::Map.find_or_create_by!(
      from_ecosystems: [old_ecosystem, new_ecosystem], to_ecosystem: new_ecosystem
    )
  end

  it 'can map from_ecosystems exercises to to_ecosystem pages' do
    mapping = map.map_exercise_ids_to_page_ids(exercise_ids: [old_exercise, new_exercise].map(&:id))
    [old_exercise, new_exercise].each do |exercise|
      expect(mapping[exercise.id]).to eq new_page.id
    end

    mapping_2 = map.map_exercise_ids_to_page_ids(
      exercise_ids: [another_old_exercise, another_new_exercise].map(&:id)
    )
    [another_old_exercise, another_new_exercise].each do |exercise|
      expect(mapping_2[exercise.id]).to eq another_new_page.id
    end

    # Try again to see that we get the same results with the cached mapping
    mapping_3 = map.map_exercise_ids_to_page_ids(exercise_ids: [
      old_exercise, new_exercise, another_old_exercise, another_new_exercise
    ].map(&:id))
    [old_exercise, new_exercise].each do |exercise|
      expect(mapping_3[exercise.id]).to eq new_page.id
    end

    [another_old_exercise, another_new_exercise].each do |exercise|
      expect(mapping_3[exercise.id]).to eq another_new_page.id
    end
  end

  it 'can map from_ecosystems pages to to_ecosystem pages' do
    mapping = map.map_page_ids(page_ids: [old_page, new_page].map(&:id))
    [old_page, new_page].each do |page|
      expect(mapping[page.id]).to eq new_page.id
    end

    mapping_2 = map.map_page_ids(page_ids: [another_old_page, another_new_page].map(&:id))
    [another_old_page, another_new_page].each do |page|
      expect(mapping_2[page.id]).to eq another_new_page.id
    end

    # Try again to see that we get the same results with the cached mapping
    mapping_3 = map.map_page_ids(page_ids: [
      old_page, new_page, another_old_page, another_new_page
    ].map(&:id))
    [old_page, new_page].each do |page|
      expect(mapping_3[page.id]).to eq new_page.id
    end

    [another_old_page, another_new_page].each do |page|
      expect(mapping_3[page.id]).to eq another_new_page.id
    end
  end

  it 'does not return exercises in other pools' do
    mapping = map.map_page_ids_to_exercise_ids(
      page_ids: [ old_page, new_page ].map(&:id), pool_type: :practice_widget
    )
    [ old_page, new_page ].each { |page| expect(mapping[page.id]).to eq [] }

    mapping_2 = map.map_page_ids_to_exercise_ids(
      page_ids: [ another_old_page, another_new_page ].map(&:id), pool_type: :practice_widget
    )
    [ another_old_page, another_new_page ].each { |page| expect(mapping_2[page.id]).to eq [] }
  end

  it 'knows if it is valid or not' do
    # The ecosystems are identical, so we can map both ways
    expect(map.is_valid).to eq true
    reverse_map = Content::Map.find_or_create_by!(from_ecosystems: [old_ecosystem, new_ecosystem],
                                                  to_ecosystem: old_ecosystem)
    expect(reverse_map.is_valid).to eq true

    # Pretend lo02 and its page were added only in the new ecosystem
    Content::Models::Exercise.where(id: another_old_lo_tag.exercises.map(&:id)).delete_all
    Content::Models::Page.where(id: another_old_lo_tag.pages.map(&:id)).delete_all
    Content::Models::Tag.where(id: another_old_lo_tag.id).delete_all

    # Reload the old ecosystem so we pick up the changes properly
    modified_old_ecosystem = another_old_lo_tag.ecosystem.reload

    # The map validity is cached, so it is still valid
    modified_map = Content::Map.find_or_create_by!(
      from_ecosystems: [modified_old_ecosystem, new_ecosystem], to_ecosystem: new_ecosystem
    )
    expect(modified_map.is_valid).to eq true
    reverse_modified_map = Content::Map.find_or_create_by!(
      from_ecosystems: [modified_old_ecosystem, new_ecosystem], to_ecosystem: modified_old_ecosystem
    )
    expect(reverse_modified_map.is_valid).to eq true

    # Clear the map cache
    Content::Models::Map.delete_all

    # We can still map forward, but the reverse map is now invalid
    modified_map = Content::Map.find_or_create_by!(
      from_ecosystems: [modified_old_ecosystem, new_ecosystem], to_ecosystem: new_ecosystem
    )
    expect(modified_map.is_valid).to eq true
    reverse_modified_map = Content::Map.find_or_create_by(
      from_ecosystems: [modified_old_ecosystem, new_ecosystem], to_ecosystem: modified_old_ecosystem
    )
    expect(reverse_modified_map.is_valid).to eq false
  end

  it 'outputs diagnostics when mapping fails' do
    # Create an invalid ecosystem mapping
    Content::Models::Exercise.where(id: another_old_lo_tag.exercises.map(&:id)).delete_all
    Content::Models::Page.where(id: another_old_lo_tag.pages.map(&:id)).delete_all
    Content::Models::Tag.where(id: another_old_lo_tag.id).delete_all

    # Reload the old ecosystem so we pick up the changes properly
    modified_old_ecosystem = another_old_lo_tag.ecosystem.reload

    expect{
      Content::Map.find_or_create_by!(
        from_ecosystems: [modified_old_ecosystem, new_ecosystem],
        to_ecosystem: modified_old_ecosystem
      )
    }.to raise_error(Content::MapInvalidError, /\AInvalid mapping/)
  end
end
