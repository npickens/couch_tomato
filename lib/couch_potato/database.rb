require 'couchrest'

module CouchPotato
  class Database
    
    class ValidationsFailedError < ::StandardError; end
    
    # Database
    class_inheritable_accessor :prefix_string  
    class_inheritable_accessor :database_name    
    class_inheritable_accessor :database_server
    class_inheritable_accessor :couchrest_db
    class_inheritable_accessor :design_docs
    
    # someday
    # class_inheritable_accessor :database_prefix
    
    # View
    # class_inheritable_accessor: 
    
    self.design_docs = {}
    self.prefix_string = ''
           
    def self.prefix (name)
       self.prefix_string =  name || '' 
    end
    def self.name (name)
      raise 'You need to provide a database name' if name.nil?
      self.database_name   = (name.class == Symbol)? name.to_s : name
    end
    
    def self.server (route)
      self.database_server = route || 'http://127.0.0.1:5984/'

      self.couchrest_db    ||= CouchRest.database("#{self.database_server}#{self.prefix_string}#{self.database_name}")
      
      begin
        self.couchrest_db.info 
      rescue RestClient::ResourceNotFound
        raise "Database '#{self.couchrest_db.name}' does not exist."
      end

    end
    
    
    def self.view(name, options={})
      # if design_docs is empty, create the default design doc      
      local_design = !options[:design_doc]? self.database_name.to_sym : options.delete(:design_doc).to_sym 
      local_view = {}
            
      raise 'A View nemonic must be specified' if name.nil?
      
      local_view[:view_name] = options.delete(:view_name) || name.to_s
      
      # if no model is given, then assume it will be returned as a Hash
      local_view[:model] = options.delete(:model) || Hash
      
      local_view[:couch_options] = options
      
      self.design_docs[local_design] ||= {}
      self.design_docs[local_design][name] = local_view

    end
    
    def self.save_document(document)
      return true unless document.dirty?
      if document.new?
        self.create_document document
      else
        self.update_document document
      end
    end
    
    def self.save_document!(document)
      save_document(document) || raise(ValidationsFailedError.new(document.errors.full_messages))
    end
    
    def self.destroy_document(document)
      document.run_callbacks :before_destroy
      document._deleted = true
      self.couchrest_db.delete_doc document.to_hash
      document.run_callbacks :after_destroy
      document._id = nil
      document._rev = nil
    end
  
    def self.load_document(id)
      raise "Can't load a document without an id (got nil)" if id.nil?
      begin
        json = self.couchrest_db.get(id)
        instance = Class.const_get(json['ruby_class']).json_create json
        instance.database = self
        instance
      rescue(RestClient::ResourceNotFound)
        nil
      end
    end
  
    def inspect
      "#<CouchPotato::Database>"
    end

    class << self
      alias_method :save, :save_document
      alias_method :save_doc, :save_document
      
      alias_method :save!, :save_document!
      alias_method :save_doc!, :save_document!
      
      alias_method :destroy, :destroy_document
      alias_method :destroy_doc, :destroy_document
      
      alias_method :load, :load_document
      alias_method :load_doc, :load_document
    end
  
    private
  
    def self.create_document(document)
      document.database = self
      document.run_callbacks :before_validation_on_save
      document.run_callbacks :before_validation_on_create
      return unless document.valid?
      document.run_callbacks :before_save
      document.run_callbacks :before_create
      res = self.couchrest_db.save_doc document.to_hash
      document._rev = res['rev']
      document._id = res['id']
      document.run_callbacks :after_save
      document.run_callbacks :after_create
      true
    end
  
    def self.update_document(document)
      document.run_callbacks :before_validation_on_save
      document.run_callbacks :before_validation_on_update
      return unless document.valid?
      document.run_callbacks :before_save
      document.run_callbacks :before_update
      res = self.couchrest_db.save_doc document.to_hash
      document._rev = res['rev']
      document.run_callbacks :after_save
      document.run_callbacks :after_update
      true
    end

   
  end
end