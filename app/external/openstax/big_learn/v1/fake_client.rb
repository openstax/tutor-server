class OpenStax::BigLearn::V1::FakeClient

  include Singleton

  #
  # API methods
  #

  def add_tags(tags)
    # Iterate through the tags, storing each in the store, overwriting any
    # with the same name.

    tags.each do |tag|
      store['tags'][tag.name] = tag.types
    end

    save!
  end

  def add_exercises(exercises)
    # Iterate through the exercises, storing each in the store, overwriting
    # any with the same ID

    exercises.each do |exercise|
      store['exercises'][exercise.uid] = exercise.tags
    end
    
    save!
  end

  def get_projection_exercises(user:, topic_tags:, filter_tags:, 
                               count:, difficulty:, allow_repetitions:)
    raise NotYetImplemented
  end

  # Normally a method like this would be protected, but since this class is for
  # fake code only, we'll leave it exposed for testing and other convenience
  def store
    @fake_store ||= FakeStore.where(name: 'openstax_biglearn_v1')
    (@fake_store.store ||= {}).tap do |s|
      s['exercises'] ||= {}
      s['tags'] ||= {}
    end
  end

  protected

  def save!
    @fake_store.save! if @fake_store.present?
  end
  
end
