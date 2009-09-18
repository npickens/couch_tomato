module CouchPotato
  module Persistence
    class SimpleProperty  #:nodoc:
      attr_accessor :name, :type
      JSON_TYPES = [String, Integer, Hash, Array, Fixnum, Float]

      def initialize(owner_clazz, name, options = {})
        if JSON_TYPES.include?(options[:type])
          raise "#{options[:type]} is a native JSON type, only custom types should be specified"
        end

        if options[:type].kind_of?(Array) && options[:type].empty?
          raise "property defined with `:type => []` but expected `:type => [SomePersistableType]`"
        end

        self.name = name
        self.type = options[:type]
        owner_clazz.class_eval do
          attr_reader name, "#{name}_was"

          def initialize(attributes = {})
            super attributes
            # assign_attribute_copies_for_dirty_tracking
          end

          # def assign_attribute_copies_for_dirty_tracking
          #   attributes.each do |name, value|
          #     self.instance_variable_set("@#{name}_was", clone_attribute(value))
          #   end if attributes
          # end
          # private :assign_attribute_copies_for_dirty_tracking

          def clone_attribute(value)
            if [Bignum, Fixnum, Symbol, TrueClass, FalseClass, NilClass, Float].include?(value.class)
              value
            else
              value.clone
            end
          end

          define_method "#{name}=" do |value|
            self.instance_variable_set("@#{name}", value)
          end

          define_method "#{name}?" do
            !self.send(name).nil? && !self.send(name).try(:blank?)
          end

          define_method "#{name}_changed?" do
            !self.instance_variable_get("@#{name}_not_changed") && self.send(name) != self.send("#{name}_was")
          end

          define_method "#{name}_not_changed" do
            self.instance_variable_set("@#{name}_not_changed", true)
          end
        end
      end

      def build(object, json)
        value = json[name.to_s]
        value = json[name.to_sym] if value.nil?

        if type.kind_of? Array
          typecasted_value = []
          value.each do |val|
            el = type[0].json_create val
            typecasted_value << el
          end
        else
          typecasted_value = if type
                               type.json_create value
                             else
                               value
                             end
        end

        object.send "#{name}=", typecasted_value
      end

      def dirty?(object)
        object.send("#{name}_changed?")
      end

      # def save(object)
      #
      #   end
      #
      #   def destroy(object)
      #
      #   end

      def serialize(json, object)
        json[name] = object.send name
      end
    end
  end
end