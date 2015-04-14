require 'rails_helper'

RSpec.describe Exercise, :type => :model do
  subject(:exercise) { FactoryGirl.create :exercise }
  let!(:lo)          { FactoryGirl.create :content_tag, tag_type: :lo }
  let!(:tag)         { FactoryGirl.create :content_tag }
  let!(:tagging_1)   { FactoryGirl.create :content_exercise_tag,
                                          tag: lo, exercise: exercise._repository }
  let!(:tagging_2)   { FactoryGirl.create :content_exercise_tag,
                                          tag: tag, exercise: exercise._repository }

  it 'exposes url, title, content, tags and los' do
    [:url, :title, :content, :tags, :los].each do |method_name|
      expect(exercise).to respond_to(method_name)
    end

    expect(exercise.url).not_to be_blank
    expect(JSON.parse(exercise.content)).not_to be_blank
    expect(exercise.tags).to include(tag.value)
    expect(exercise.tags).to include(lo.value)
    expect(exercise.los).not_to include(tag.value)
    expect(exercise.los).to include(lo.value)
  end
end
