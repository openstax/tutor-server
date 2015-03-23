class OpenStax::BigLearn::V1::FakeClient

  include Singleton

  #
  # API methods
  #

  def add_tags(tags)
    # Iterate through the tags, storing each in the store, overwriting any
    # with the same name.

    [tags].flatten.each do |tag|
      store['tags'][tag.text] = tag.types
    end

    save!
  end

  def add_exercises(exercises)
    # Iterate through the exercises, storing each in the store, overwriting
    # any with the same ID

    [exercises].flatten.each do |exercise|
      store['exercises'][exercise.uid] = exercise.tags
    end
    
    save!
  end

  def get_projection_exercises(user:, topic_tags:, filter_tags:, 
                               count:, difficulty:, allow_repetitions:)
    raise NotYetImplemented
  end

  #
  # Debugging methods
  #

  def store_tags_copy
    store['tags'].clone
  end

  def store_exercises_copy
    store['exercises'].clone
  end

  def reload!
    store(true)
  end

  protected

  def store(reload=false)
    # We need to load the store from the DB if
    # (1) we haven't yet done so
    # (2) someone wants us to load it
    # (3) We have loaded it but it is no longer in the DB (which can happen in tests)

    if @fake_store.nil? || 
       reload ||  
       ::FakeStore.where(name: 'openstax_biglearn_v1').none?
       
      @fake_store = ::FakeStore.find_or_create_by(name: 'openstax_biglearn_v1')
    end

    (@fake_store.data ||= {}).tap do |data|
      data['exercises'] ||= {}
      data['tags'] ||= {}
    end
  end

  def save!
    @fake_store.save! if @fake_store.present?
  end

end
