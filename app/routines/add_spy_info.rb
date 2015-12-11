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

  def values_from(value)
    case value
    when Hash
      value.each_with_object({}) do |(key, value), hash|
        hash[key] = values_from(value)
      end
    else
      val = {}
      val[:"#{value.class.name.demodulize.underscore}_id"] = value.id if value.respond_to?(:id)
      val[:"#{value.class.name.demodulize.underscore}_title"] = value.title \
        if value.respond_to?(:title)
      val
    end
  end
end
