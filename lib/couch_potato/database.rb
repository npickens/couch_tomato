require 'couchrest'
require 'pp'

module CouchPotato
  class Database
    
    class ValidationsFailedError < ::StandardError; end
    
    # Database
    class_inheritable_accessor :prefix_string  
    class_inheritable_accessor :database_name    
    class_inheritable_accessor :database_server
    class_inheritable_accessor :couchrest_db
    class_inheritable_accessor :views
    
    self.views = {}
    self.prefix_string = ''
           
    def self.prefix (name)
       self.prefix_string =  name || ''
    end
    def self.name (name)
      raise 'You need to provide a database name' if name.nil?
      self.database_name   = (name.class == Symbol)? name.to_s : name
    end
    
    # TODO: specify db=>host mapping in yaml, and allow to differ per environment 
    def self.server (route='http://127.0.0.1:5984/')
      self.database_server = route 
      self.prefix_string ||= ''
      
      tmp_prefix = self.prefix_string + '_'  unless self.prefix_string.empty?
      tmp_server = self.database_server + '/' unless self.database_server.match(/\/$/)
      tmp_suffix = '_' + Rails.env  if defined?(Rails)

      
      self.couchrest_db ||= CouchRest.database("#{tmp_server}#{tmp_prefix}#{self.database_name}#{tmp_suffix}")
      begin
        self.couchrest_db.info 
      rescue RestClient::ResourceNotFound
        raise "Database '#{tmp_prefix}#{self.database_name}#{tmp_suffix}' does not exist."
      end

    end
    
    
    def self.view(name, options={})
      raise 'A View nemonic must be specified' if name.nil?
      self.views[name] = {}     
      self.views[name][:design_doc] = !options[:design_doc] ? self.database_name.to_sym : options.delete(:design_doc).to_sym             
      self.views[name][:view_name] = options.delete(:view_name) || name.to_s
      self.views[name][:model] = options.delete(:model)
      self.views[name][:couch_options] = options
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
  
    def self.load_document(id, options ={})
      raise "Can't load a document without an id (got nil)" if id.nil?
      
      begin
        # json = self.couchrest_db.get(id)
        # instance = Class.const_get(json['ruby_class']).json_create json
        # # instance.database = self
        # instance
        json = self.couchrest_db.get(id)
        if options[:model] == :raw || ! json['ruby_class']
          {}.merge(json)
        else
          instance = Class.const_get(json['ruby_class']).json_create json
          instance
        end
      rescue(RestClient::ResourceNotFound) #'Document not found'
        nil
      end
    end
  
    def self.inspect
      "#<CouchPotato::Database>"
    end
    
    def self.query_view!(name, options={})
      view = self.views[name]
      raise 'View does not exist' unless view
      
      begin
        tmp_couch_opts = view[:couch_options] || {}
        pr_options = options.merge(tmp_couch_opts)
        results = self.query_view(name, pr_options) || []
        # puts '======================'
        #  pp results
        #  puts '======================'
        self.process_results(name, results, pr_options)
      rescue RestClient::ResourceNotFound# => e
        raise
      end
      
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
      # document.database = self
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

    def self.query_view(name,parameters)
      self.couchrest_db.view "#{self.views[name][:design_doc]}/#{self.views[name][:view_name]}", parameters
    end
    
    def self.process_results(name, results, options ={})
      view = self.views[name]
      couch_opts = view[:couch_options] || {}
      
      return_raw = !couch_opts[:reduce].nil? || view[:model] == :raw || options[:model] == :raw
      # TODO: This code looks like C (REVIEW)
      results['rows'].map do |row|
        if return_raw
          row['value']
        elsif view[:model].nil?
          if row['value']['ruby_class'].nil?
            row['value']
          else
            Class.const_get(row['value']['ruby_class']).json_create row['value']
          end
        else
          view[:model].json_create row['value']
        end                
      end # results do
    end
    
  end # class
end # module
