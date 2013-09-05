module EvernoteOAuth

  module ThriftClientDelegation
    def method_missing(name, *args, &block)
      method = @client.class.instance_method(name)
      if method.arity != args.size
        new_args = args.dup.unshift(@token)
        begin
          result = @client.send(name, *new_args, &block)
        rescue ArgumentError => e
          result = @client.send(name, *args, &block)
        end
      else
        result = @client.send(name, *args, &block)
      end

      attr_name = underscore(self.class.name.gsub(/::Store$/, '').split('::').last).to_sym
      attr_value = self
      [result].flatten.each{|r|
        begin
          r_singleton_class = class << r; self; end
          r_singleton_class.send(:define_method, [attr_name]) {attr_value}
        rescue TypeError # Fixnum/TrueClass/FalseClass/NilClass
          next
        end
      }
      result
    end

    private
    def underscore(word)
      word.to_s.gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
        gsub(/([a-z\d])([A-Z])/,'\1_\2').
        tr("-", "_").
        downcase
    end
  end

end
