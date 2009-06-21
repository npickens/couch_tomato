# todo: depend on active support gem?
require 'active_support'

module CouchPotato
  class Database
    
    class ValidationsFailedError < ::StandardError; end
        
    
    class_inheritable_accessor :database_prefix 
    class_inheritable_accessor :database_name    
    # class_inheritable_accessor :db
    class_inheritable_accessor :couchrest_db
    class_inheritable_accessor :designs
    
    self.designs = {}
           
    def initialize(couchrest_database)
      
      
      @database = couchrest_database
      begin
        couchrest_database.info 
      rescue RestClient::ResourceNotFound
        raise "Database '#{couchrest_database.name}' does not exist."
      end
    end
    


    def self.prefix(prefix)
      self.database_prefix = prefix
    end
    

    def self.name(name)
      self.database_name = name
    end
    
    # Asume that it is always running on localhost for now.
    
    # class_inheritable_accessor :database_server
    # def self.server(server)
    #   self.database_server = server
    # end
    

    
    # Returns a database instance which you can then use to create objects and query views.
    # You have to set self.database_name before this works.
    # def self.database
    #   self.db ||= new(self.couchrest_database)
    #   # new(self.couchrest_database)
    # end
    
    # Returns the underlying CouchRest database object if you want low level access to your 
    # CouchDB. You have to set the self.database_name before this works.
    def self.couchrest_database
      self.couchrest_db ||= CouchRest.database(full_url_to_database)
    end
    
    def self.view(view_name, options={})
      puts "hello " * 10
      design_name = options.delete(:design) || self.database_name.to_sym      
      model = options[:model] || :raw
      
      design = self.designs[design_name] ||= {}
      design[view_name] = options # should this have a value??? wrong structure?
    end
    
    # def view(options)
    #   
    #   # results = CouchPotato::View::ViewQuery.new(database,
    #   #   spec.design_document, spec.view_name, spec.map_function,
    #   #   spec.reduce_function).query_view!(spec.view_parameters)
    #   # spec.process_results results
    # end
  
    def save_document(document)
      return true unless document.dirty?
      if document.new?
        create_document document
      else
        update_document document
      end
    end
    alias_method :save, :save_document
  
    def save_document!(document)
      save_document(document) || raise(ValidationsFailedError.new(document.errors.full_messages))
    end
    alias_method :save!, :save_document!
  
    def destroy_document(document)
      document.run_callbacks :before_destroy
      document._deleted = true
      database.delete_doc document.to_hash
      document.run_callbacks :after_destroy
      document._id = nil
      document._rev = nil
    end
    alias_method :destroy, :destroy_document
  
    def load_document(id)
      raise "Can't load a document without an id (got nil)" if id.nil?
      begin
        json = database.get(id)
        instance = Class.const_get(json['ruby_class']).json_create json
        instance.database = self
        instance
      rescue(RestClient::ResourceNotFound)
        nil
      end
    end
    alias_method :load, :load_document
  
    def inspect
      "#<CouchPotato::Database>"
    end
  
    private
  
    def create_document(document)
      document.database = self
      document.run_callbacks :before_validation_on_save
      document.run_callbacks :before_validation_on_create
      return unless document.valid?
      document.run_callbacks :before_save
      document.run_callbacks :before_create
      res = database.save_doc document.to_hash
      document._rev = res['rev']
      document._id = res['id']
      document.run_callbacks :after_save
      document.run_callbacks :after_create
      true
    end
  
    def update_document(document)
      document.run_callbacks :before_validation_on_save
      document.run_callbacks :before_validation_on_update
      return unless document.valid?
      document.run_callbacks :before_save
      document.run_callbacks :before_update
      res = database.save_doc document.to_hash
      document._rev = res['rev']
      document.run_callbacks :after_save
      document.run_callbacks :after_update
      true
    end
    
    def self.full_url_to_database
      raise("No Database configured. Set #{self.class}.database_name") unless self.database_name
      self.database_server ? "#{self.database_server}#{self.database_name}" : "http://127.0.0.1:5984/#{self.database_name}"
    end
    
    def database
      @database
    end
  
  end
end