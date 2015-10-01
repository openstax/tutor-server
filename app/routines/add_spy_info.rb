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
    when Content::Models::Ecosystem
      { ecosystem_id: value.id, ecosystem_title: value.title }
    else
      { "#{value.class.name.demodulize.underscore}_id" => value.id }
    end
  end
end
