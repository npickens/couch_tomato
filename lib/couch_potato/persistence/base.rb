module CouchPotato
  module Persistence
    module Base
      # initialize a new instance of the model optionally passing it a hash of attributes.
      # the attributes have to be declared using the #property method
      # 
      # example: 
      #   class Book
      #     include CouchPotato::Persistence
      #     property :title
      #   end
      #   book = Book.new :title => 'Time to Relax'
      #   book.title # => 'Time to Relax'
      def initialize(attributes = {})
        attributes.each do |name, value|
          self.send("#{name}=", value)
        end if attributes
      end
    
      # assign multiple attributes at once.
      # the attributes have to be declared using the #property method
      #
      # example:
      #   class Book
      #     include CouchPotato::Persistence
      #     property :title
      #     property :year
      #   end
      #   book = Book.new
      #   book.attributes = {:title => 'Time to Relax', :year => 2009}
      #   book.title # => 'Time to Relax'
      #   book.year # => 2009
      def attributes=(hash)
        hash.each do |attribute, value|
          self.send "#{attribute}=", value
        end
      end
    
      # returns all of a model's attributes that have been defined using the #property method as a Hash
      #
      # example:
      #   class Book
      #     include CouchPotato::Persistence
      #     property :title
      #     property :year
      #   end
      #   book = Book.new :year => 2009
      #   book.attributes # => {:title => nil, :year => 2009}
      def attributes
        self.class.properties.inject({}) do |res, property|
          property.serialize(res, self)
          res
        end
      end
    
      def ==(other) #:nodoc:
        other.class == self.class && self.to_json == other.to_json
      end
    
    end
  end
end
