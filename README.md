## This Fork of Couch Potato

We're huge fans of Couch Potato. We love it's advocacy for using Couch naturally (not trying to make it look like a SQL database). In this fork, we're trying out a few ideas that will (hopefully) further this pursuit.

### Multi-Database Support

Couch makes it dead-simple to manage multiple databases. For large data-sets, it's very important to separate unrelated documents into separate databases. Couch Potato should make this easy.

Currently, you save a document by using a database, like so:

    user = User.new :name => 'joe'
    CouchPotato.database.save_document user # or save_document!

Love it. Except it needs to work well with multiple databases. Couch Potato supports this already:

    couchrest_database = CouchRest.database!("http://#{host}:#{port}/#{base_name}_#{name}_#{RAILS_ENV}")
    user_db = CouchPotato::Database.new(couchrest_database)
    
    user = User.new :name => 'joe'
    user_db.save_document user # or save_document!

We want to take this one step further:

    user = User.new :name => 'joe'
    UserDb.save_document user
    UserDb.view :by_created_at
    UserDb.view :by_created_at, :raw => true
    UserDb.view :by_created_at, :key => [2009, 6, 8], :raw => true

### Each view should determine the model for its values

Views return arbitrary hashes. Often our views' value is an entire document (or more correctly, utilize `emit(key, null)` combined with `:include_docs => true`). When this is true, Couch Potato helps you out. But, Couch Potato should help us out even if our view output is different than our model (and for us, this is often the case).

Instead of views being declared and defined inside a model, we'll define views on the database (this is arguably more Couch-like). When views are declared, they'll stipulate whether their results should be 'raw' or a particular model type.

    class UserDb > CouchPotato::Database
      view :by_created_at, User
      view :count # raw
    end

### Store view definitions on the file system

Rather than having Ruby generate JavaScript or writing JavaScript in our Ruby code as a string, we prefer to define our views in files on the file system:

    RAILS_ROOT/db/views/users/*-map.js
    RAILS_ROOT/db/views/users/*-reduce.js
    
The reduce is optional. If you want to define views in a specific design document (called 'lazy'), you can do so:

    RAILS_ROOT/db/views/users/lazy/*.js

We'll use a generator to take some of the grunt work out:

    script/generate view users by_created_at
    script/generate view users/lazy by_birthday
    script/generate view users by_created_on map reduce

Rake tasks apply the views on the file system to Couch:

    rake couch_potato:views:apply

This is similar to how 'CouchApp' (used to?) work. There'll also be a task to show detailed information about the differences between the views in Couch and on the file system:

    rake couch_potato:views:dirty

### Remove dynamically generated views

We've found that we generally need to write JavaScript to get the view behavior we need, and, for both conceptual and implementation complexity reasons, we value having all the views contained in one place--the file system.

The current implementation of dynamic views has some limitations. Consider the following dynamic view definition:

    view :all, :key => :created_at

Suppose you wanted to change that to:

    view :all, :key => :updated_at

Your change would not be reflected until you manually deleted the corresponding design document from CouchDB, since the view is only created if it doesn't already exist or if an exception is generated. This could be troublesome in development, and really bad in production. A potential solution would be to compare the content of each view within each design document with the content implied by the Ruby view declaration. If the contents differ, then the design document needs to be updated with the latest content. This would need to be done before each view query, or more likely, done only the first time a view is queried in a Ruby process's lifetime.

Even with these proposed improvements, this strategy doesn't work well for us. We have some large data-sets in production, and our views need to be inserted and warmed up before bringing the application online (building views the first time can take several minutes). If a view hasn't been inserted and is queried at runtime, we want to fail-fast with an error rather than the application hanging for several minutes while the view is inserted and built. Failing-fast also helps us recognize potential problems while working in development with data-sets small enough that we wouldn't notice a potential issue.

Certainly the dynamically generated views strategy could be changed to fail-fast with an error when views are out of sync, requiring explicit insertion/update of views.

### Multiple design documents per database

CouchDB supports multiple design documents per database. There's an important semantic consideration: all views in a design document are updated if any one view needs to be updated. To improve the read performance of couch views under high-volume reads and writes, you could organize views that don't need to be as timely into a separate design document named 'lazy', and always include the `stale=true` couch option in queries to views defined in the 'lazy' design document. You could then have a script that ran periodically to trigger the 'lazy' views to update.

    class UserDb > CouchPotato::Database
      name :users
      
      view :by_created_at, User
      view :count # raw
      view 'lazy/count_created_by_date'
    end

We have not yet found a use for this, or demonstrated that the claimed performance benefit actually exists (it originated from the CouchDB docs, wiki or list or some-such). But, it does show a instance where this approach to representing views maps fairly directly to CouchDB functionality.


## Couch Potato

... is a persistence layer written in ruby for CouchDB.

### Mission

The goal of Couch Potato is to create a minimal framework in order to store and retrieve Ruby objects to/from CouchDB and create and query views.

It follows the document/view/querying semantics established by CouchDB and won't try to mimic ActiveRecord behavior in any way as that IS BAD.

Code that uses Couch Potato should be easy to test.

Lastly Couch Potato aims to provide a seamless integration with Ruby on Rails, e.g. routing, form helpers etc.

### Core Features

* persisting objects by including the CouchPotato::Persistence module
* declarative views with either custom or generated map/reduce functions
* extensive spec suite

### Installation

Couch Potato is hosted as a gem on github which you can install like this:

    sudo gem source --add http://gems.github.com # if you haven't already
    sudo gem install langalex-couch_potato

#### Using with your ruby application:

    require 'rubygems'
    gem 'langalex-couch_potato'
    require 'couch_potato'

Alternatively you can download or clone the source repository and then require lib/couch_potato.rb.

You MUST specificy the name of the database:

    CouchPotato::Config.database_name = 'name of the db'

The server URL will default to http://localhost:5984/ unless specified with:

    CouchPotato::Config.database_server = "http://example.com:5984/"

#### Using with Rails

Add to your config/environment.rb:

    config.gem 'langalex-couch_potato', :lib => 'couch_potato', :source => 'http://gems.github.com'

Then create a config/couchdb.yml:

    development: development_db_name
    test: test_db_name
    production: http://db.server/production_db_name

Alternatively you can also install Couch Potato directly as a plugin.

### Introduction

This is a basic tutorial on how to use Couch Potato. If you want to know all the details feel free to read the specs.

#### Save, load objects

First you need a class.

    class User
    end

To make instances of this class persistent include the persistence module:

    class User
      include CouchPotato::Persistence
    end

If you want to store any properties you have to declare them:

    class User
      include CouchPotato::Persistence

      property :name
    end

Properties can be of any type:

    class User
      include CouchPotato::Persistence

      property :address, :type => Address
    end

Now you can save your objects. All database operations are encapsulated in the CouchPotato::Database class. This separates your domain logic from the database access logic which makes it easier to write tests and also keeps you models smaller and cleaner.

    user = User.new :name => 'joe'
    CouchPotato.database.save_document user # or save_document!

You can of course also retrieve your instance:

    CouchPotato.database.load_document "id_of_the_user_document" # => <#User 0x3075>


#### Properties

You can access the properties you declared above through normal attribute accessors.

    user.name # => 'joe'
    user.name = {:first => ['joe', 'joey'], :last => 'doe', :middle => 'J'} # you can set any ruby object that responds_to :to_json (includes all core objects)
    user._id # => "02097f33a0046123f1ebc0ebb6937269"
    user._rev # => "2769180384"
    user.created_at # => Fri Oct 24 19:05:54 +0200 2008
    user.updated_at # => Fri Oct 24 19:05:54 +0200 2008
    user.new? # => false

If you want to have properties that don't map to any JSON type, i.e. other than String, Number, Boolean, Hash or Array you have to define the type like this:

    class User
      property :date_of_birth, :type => Date
    end

The date_of_birth property is now automatically serialized to JSON and back when storing/retrieving objects.

#### Dirty tracking

CouchPotato tracks the dirty state of attributes in the same way ActiveRecord does:

    user = User.create :name => 'joe'
    user.name # => 'joe'
    user.name_changed? # => false
    user.name_was # => nil

You can also force a dirty state:

    user.name = 'jane'
    user.name_changed? # => true
    user.name_not_changed
    user.name_changed? # => false
    CouchPotato.database.save_document user # does nothing as no attributes are dirty


#### Object validations

Couch Potato uses the validatable library for vaidation (http://validatable.rubyforge.org/)\

    class User
      property :name
      validates_presence_of :name
    end

    user = User.new
    user.valid? # => false
    user.errors.on(:name) # => [:name, 'can't be blank']

#### Finding stuff

In order to find data in your CouchDB you have to create a view first. Couch Potato offers you to create and manage those views for you. All you have to do is declare them in your classes:

    class User
      include CouchPotato::Persistence
      property :name

      view :all, :key => :created_at
    end

This will create a view called "all" in the "user" design document with a map function that emits "created_at" for every user document.

    CouchPotato.database.view User.all

This will load all user documents in your database sorted by created_at.

    CouchPotato.database.view User.all(:key => (Time.now- 10)..(Time.now), :descending => true)

Any options you pass in will be passed onto CouchDB.

Composite keys are also possible:

    class User
      property :name

      view :all, :key => [:created_at, :name]
    end

The creation of views is based on view specification classes (see the CouchPotato::View module). The above code uses the ModelViewSpec class which is used to find models by their properties. For more sophisticated searches you can use other view specifications (either use the built-in or provide your own) by passing a type parameter:

If you have larger structures and you only want to load some attributes you can use the PropertiesViewSpec (the full class name is automatically derived):

    class User
      property :name
      property :bio

      view :all, :key => :created_at, :properties => [:name], :type => :properties
    end

  CouchPotato.database.view(User.everyone).first.name # => "joe"
  CouchPotato.database.view(User.everyone).first.bio # => nil

You can also pass in custom map/reduce functions with the custom view spec:

    class User
      view :all, :map => "function(doc) { emit(doc.created_at, null)}", :include_docs => true, :type => :custom
    end

If you don't want the results to be converted into models the raw view is your friend:

    class User
      view :all, :map => "function(doc) { emit(doc.created_at, doc.name)}", :type => :raw
    end

When querying this view you will get the raw data returned by CouchDB which looks something like this: {'total_entries': 2, 'rows': [{'value': 'alex', 'key': '2009-01-03 00:02:34 +000', 'id': '75976rgi7546gi02a'}]}

To process this raw data you can also pass in a results filter:

    class User
      view :all, :map => "function(doc) { emit(doc.created_at, doc.name)}", :type => :raw, :results_filter => lambda {|results| results['rows'].map{|row| row['value']}}
    end

In this case querying the view would only return the emitted value for each row.

You can pass in your own view specifications by passing in :type => MyViewSpecClass. Take a look at the CouchPotato::View::*ViewSpec classes to get an idea of how this works.

#### Associations

Not supported. Not sure if they ever will be. You can implement those yourself using views and custom methods on your models.

#### Callbacks

Couch Potato supports the usual lifecycle callbacks known from ActiveRecord:

    class User
      include CouchPotato::Persistence

      before_create :do_something_before_create
      before_update {|user| user.do_something_on_update}
    end

This will call the method do_something_before_create before creating an object and run the given lambda before updating one. Lambda callbacks get passed the model as their first argument. Method callbacks don't receive any arguments.

Supported callbacks are: :before_validation, :before_validation_on_create, :before_validation_on_update, :before_validation_on_save, :before_create, :after_create, :before_update, :after_update, :before_save, :after_save, :before_destroy, :after_destroy.

If you need access to the database in a callback: Couch Potato automatically assigns a database instance to the model before saving and when loading. It is available as _database_ accessor from within your model instance.

#### Testing

To make testing easier and faster database logic has been put into its own class, which you can replace and stub out in whatever way you want:

    class User
      include CouchPotato::Persistence
    end

    # RSpec
    describe 'save a user' do
      it 'should save' do
        couchrest_db = stub 'couchrest_db',
        database = CouchPotato::Database.new couchrest_db
        user = User.new
        couchrest_db.should_receive(:save_doc).with(...)
        database.save_document user
      end
    end

By creating you own instances of CouchPotato::Database and passing them a fake CouchRest database instance you can completely disconnect your unit tests/spec from the database.

### Helping out

Please fix bugs, add more specs, implement new features by forking the github repo at http://github.com/langalex/couch_potato.

You can run all the specs by calling 'rake spec_unit' and 'rake spec_functional' in the root folder of Couch Potato. The specs require a running CouchDB instance at http://localhost:5984

I will only accept patches that are covered by specs - sorry.

### Contact

If you have any questions/suggestions etc. please contact me at alex at upstream-berlin.com or @langalex on twitter.
