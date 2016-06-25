module JsonSerialize
  module ClassMethods
    DEFAULT_CONVERSION_METHODS = {
      Hash => :to_h,
      Array => :to_a,
      String => :to_s,
      Integer => :to_i
    }

    def json_serialize(attribute, type, options = {})
      options[:typecast] = :after_initialize unless options.has_key?(:typecast)
      options[:setter_method] ||= "#{attribute}=".to_sym
      options[:typecast_method] ||= "typecast_#{attribute}".to_sym
      options[:conversion_method] ||= DEFAULT_CONVERSION_METHODS[type]

      serialize attribute, JSON

      send(options[:typecast], options[:typecast_method]) if options[:typecast].present?

      define_method(options[:typecast_method]) do
        return unless has_attribute?(attribute)

        value = send attribute
        return if options[:array] ? value.to_a.all?{ |val| val.is_a? type } : value.is_a?(type)

        raise "Cannot convert object of type #{value.class.name} into #{type.name}" +
              " without specifying the :conversion_method" if options[:conversion_method].nil?

        typecast_value = options[:array] ? \
                           value.to_a.map(&options[:conversion_method]) :
                           value.send(options[:conversion_method])
        send options[:setter_method], typecast_value
      end

      protected options[:typecast_method]

    end
  end
end

ActiveRecord::Base.extend JsonSerialize::ClassMethods
