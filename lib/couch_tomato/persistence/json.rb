module CouchTomato
  module Persistence
    module Json
      def self.included(base)
        base.extend ClassMethods
      end
      
      # returns a JSON representation of a model in order to store it in CouchDB
      def to_json(*args)
        to_hash.to_json(*args)
        # to_json(*args)
      end
      
      # returns all the attributes, the ruby class and the _id and _rev of a model as a Hash
      def to_hash
        (self.class.properties).inject({}) do |props, property|
          property.serialize(props, self)
          props
        end.merge('ruby_class' => self.class.name).merge(id_and_rev_json)
      end
      
      private
      
      def id_and_rev_json
        ['_id', '_rev', '_deleted'].inject({}) do |hash, key|
          hash[key] = self.send(key) unless self.send(key).nil?
          hash
        end
      end
      
      module ClassMethods
        
        # creates a model instance from JSON
        def json_create(json, meta={})
          return if json.nil?
          instance = self.new
          instance._id = json[:_id] || json['_id']
          instance._rev = json[:_rev] || json['_rev']
          properties.each do |property|
            property.build(instance, json)
          end
          instance.metadata = meta
          instance
        end
      end
    end
  end
end
