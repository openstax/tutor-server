# Add spy information to a model that has a "spy" field
#
class AddSpyInfo
  lev_routine express_output: :to

  def exec(to:, from:, save: false)
    to[:spy] ||= {}
    # from may be either an array or a single model
    # The glob will convert to array regardless
    [*from].each do | src |
      to[:spy].merge!( values_from( src ) )
    end
    to.save! if save
    outputs[:to] = to
  end

  # Returns a hash that represents the given value in some way
  def values_from(val)
    case val
    when Array
      val.map{ |value| values_from(value) }.reduce({}, :merge)
    when Hash
      val.each_with_object({}) { |(key, value), hash| hash[key] = values_from(value) }
    else
      hash = {}
      hash[:"#{val.class.name.demodulize.underscore}_id"] = val.id if val.respond_to?(:id)
      hash[:"#{val.class.name.demodulize.underscore}_title"] = val.title if val.respond_to?(:title)
      hash
    end
  end
end
