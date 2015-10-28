module ModifiedWrapper
  def self.included(base)
    base.send(:include, TypeVerification)
    base.extend ClassMethods
  end

  def initialize(strategy:)
    @strategy = strategy
  end

  # Wrappers are equal if the strategies are equal
  def ==(other)
    self.class == other.class && strategy == other.strategy
  end

  # Hash key equality
  def eql?(other)
    self.class.eql?(other.class) && strategy.eql?(other.strategy)
  end

  # Hash function
  def hash
    self.class.hash ^ strategy.hash
  end

  module ClassMethods
    def use_strategy(klass, options = {})
      @strategy_class = klass
      define_instance_methods(options[:instance_methods])
    end

    def wrap_attributes(model, *attributes)
      attributes.map.each do | attr |
        col = model.columns.find{|column| column.name == attr.to_s }
        type = case col.cast_type.type
               when :integer; Integer
               when :string;  String
               when :boolean; :boolean
               else
                 raise "Unable to determine type of attribute #{attr}, sql type was #{col.cast_type.type}"
               end
        _define_dynamic_wrapping(attr, type)
      end
    end

    private
    def _define_dynamic_wrapping(name, type)
      name = name.to_sym

      define_method(name) do
        verify_and_return strategy.send(name), klass: type, error: StrategyError
      end
    end

    def define_instance_methods(methods_hash)
      methods_hash.each do |name, klass|
        define_method(name) do
          verify_and_return strategy.send(name), klass: klass, error: StrategyError
        end
      end
    end
  end

  private
  attr_reader :strategy
end
