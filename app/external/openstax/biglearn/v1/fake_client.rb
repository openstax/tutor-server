class OpenStax::Biglearn::V1::FakeClient

  include Singleton

  #
  # API methods
  #

  def get_clue(roles:, tags:)
    rand(0.0..1.0)
  end

  def add_exercises(exercises)
    # Iterate through the exercises, storing each in the store, overwriting
    # any with the same ID

    [exercises].flatten.each do |exercise|
      store['exercises'][exercise.url] = exercise.tags
    end

    save!
  end

  def get_projection_exercises(role:, tag_search:, count:, difficulty:, allow_repetitions:)
    # Get the matches (no SPARFA obviously :)
    matches = store_exercises_copy.select do |uid, tags|
      tags_match_condition?(tags, tag_search)
    end

    # Limit the results to the desired number
    results = matches.first(count)

    # If we didn't get as many as requested and repetitions are allowed,
    # pad the results, repeat the matches until we have enough, making
    # sure to clip at the desired count in case we go over.
    while (allow_repetitions && results.length < count)
      results.push(*matches)
    end
    results = results.first(count).collect{|r| r[0]}
  end

  # Example conditions: { _and: [ { _or: ['a', 'b', 'c'] }, 'd']  }
  def tags_match_condition?(tags, condition)
    case condition
    when Hash
      if condition.size != 1 then raise IllegalArgument, "too many hash condition" end
      case condition.first[0]
      when :_and
        condition.first[1].all?{|c| tags_match_condition?(tags, c)}
      when :_or
        condition.first[1].any?{|c| tags_match_condition?(tags, c)}
      else raise NotYetImplemented, "Unknown boolean symbol #{condition.first[0]}"
      end
    when String
      tags.include?(condition)
    else raise IllegalArgument
    end
  end

  #
  # Debugging methods
  #

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

    @fake_store.data ||= {}

    @fake_store.data['exercises'] ||= {}

    @fake_store.data
  end

  def save!
    @fake_store.save! if @fake_store.present?
  end

end
