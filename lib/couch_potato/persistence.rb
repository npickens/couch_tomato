require 'digest/md5'
require File.dirname(__FILE__) + '/database'
require File.dirname(__FILE__) + '/persistence/properties'
require File.dirname(__FILE__) + '/persistence/magic_timestamps'
require File.dirname(__FILE__) + '/persistence/callbacks'
require File.dirname(__FILE__) + '/persistence/json'
require File.dirname(__FILE__) + '/persistence/dirty_attributes'
require File.dirname(__FILE__) + '/persistence/validation'



module CouchPotato
  module Persistence
    module Nested
      include Base
      def self.included(base)
        base.send :include, Properties, Callbacks, Validation#, Json#, CouchPotato::View::CustomViews
        base.send :include, DirtyAttributes
        # base.send :include, MagicTimestamps
        
        base.extend ClassMethods
      end
      
      def to_json(*args)
        to_hash.to_json(*args)
        # to_json(*args)
      end
      
      # returns all the attributes, the ruby class and the _id and _rev of a model as a Hash
      def to_hash
        (self.class.properties).inject({}) do |props, property|
          property.serialize(props, self)
          props
        end
      end
      
      private
      
      module ClassMethods
        # creates a model instance from JSON
        def json_create(json, meta={})
          return if json.nil?
          instance = self.new
          # instance._id = json[:_id] || json['_id']
          # instance._rev = json[:_rev] || json['_rev']
          properties.each do |property|
            property.build(instance, json)
          end
          instance
        end
      end
      
    end
    
    include Base

    def self.included(base)
      base.send :include, Properties, Callbacks, Validation, Json#, CouchPotato::View::CustomViews
      base.send :include, DirtyAttributes
      base.send :include, MagicTimestamps
      base.class_eval do
        attr_accessor :_id, :_rev, :_attachments, :_deleted
        attr_accessor :metadata
        alias_method :id, :_id
      end
    end

    # returns true if a  model hasn't been saved yet, false otherwise
    def new?
      _rev.nil?
    end
    alias_method :new_record?, :new?

    # returns the document id
    # this is used by rails to construct URLs
    # can be overridden to for example use slugs for URLs instead if ids
    def to_param
      _id
    end
    
  end
  
end