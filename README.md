#Couch Tomato
*A Ruby persistence layer for CouchDB, inspired by and forked from Couch Potato*

##Quick Start
###Installing Couch Tomato
Couch Tomato is hosted on [gemcutter.org](http://gemcutter.org), and can be installed as follows:

    sudo gem install couch_tomato --source http://gemcutter.org

###Post Installation Requirements
`root` in a path refers to `Rails.root` if you are using Rails, and the root level of any Ruby project if you are not using Rails. With the couch\_tomato gem installed, enable the Thor tasks by creating a file `couch_tomato.thor` as shown below:

####couch\_tomato.thor

    couch_tomato_gem = Gem.searcher.find('couch_tomato')
    Dir["#{couch_tomato_gem.full_gem_path}/lib/tasks/*.thor"].each { |ext| load ext } if couch_tomato_gem

`couch_tomato.thor` can be saved to `Rails.root/lib/tasks` for Rails projects or to the root level of a regular Ruby app. Thor tasks associated with Couch Tomato are available under the `ct` namespace. To setup the Couch Tomato folder structure and config file in a Rails project, run the following:

    thor ct:init
    
The above will create a folder `couchdb` in `root`, along with `root/couchdb/migrate` and `root/couchdb/views`. The init task will also generate a sample Couch Tomato config file `couch_tomato.yml.example` in `root/config` as given below: 

####couch\_tomato.yml.example

    defaults: &defaults
      couchdb_address:         127.0.0.1
      couchdb_port:            5984
      couchdb_basename:        your_project_name

    development:
      <<: *defaults

    test:
      <<: *defaults

    production:
      <<: *defaults

Modify `couchdb_address`, `couchdb_port`, and `couchdb_basename` to correspond to the ip/address, port number, and name of your project respectively. You can optionally choose to suffix all your databases names by adding a `couchdb_suffix` field. Rename/copy `couch_tomato.yml.example` to `couch_tomato.yml`. 

Finally, you will need to populate the values in CouchTomato::Config. Put

    CouchTomato::Config.set_config_yml path
    
somewhere in your app (i.e. in an initializer for Rails). This will load `couch_tomato.yml` into CouchTomato::Config. If path is not specified, Couch Tomato will look for the default `root/config/couch_tomato.yml`. If you chose to not create a `couch_tomato.yml`, you can populate the fields of `CouchTomato::Config` manually. Couch Tomato is now ready to be used.

##Using Couch Tomato
### Multi-Database Support
CouchDB makes it dead-simple to manage multiple databases. For large data-sets, it's very important to separate unrelated documents into separate databases. Couch Tomato assumes (but doesn't force) the use of multiple databases.

    class UserDb < CouchTomato::Database
      name "users"
      ...
    end

    class StatDb < CouchTomato::Database
      ...
    end

    UserDb.save_doc(User.new({:name => 'Joe'}))
    5_000.times { StatDb.save_doc(Stat.new({:metric => 10_000 * rand})) }

A name can be specified for a specific database as shown in UserDb, otherwise, the class name is used.

###Each view determines the model for its values
Views return arbitrary hashes. Often a view's value is an entire document (or more correctly, utilize `emit(key, null)` combined with `:include_docs => true`). But, a view's value is also often completely independent of the structure of the underlying documents.

Define views on the database rather than inside a model (this is arguably more Couch-like). Each views declaration stipulates whether their results should be 'raw' hashes or a particular model type.

    class UserDb < CouchTomato::Database
      name "users"
      
      view :by_created_at, User
      view :count # raw
    end

###Store view definitions on the file system
Rather than having Ruby generate JavaScript or writing JavaScript in our Ruby code as a string, define views in files on the file system:

    root/couchdb/views/users/*-map.js
    root/couchdb/views/users/*-reduce.js
    
The reduce is optional. If you want to define views in a specific design document (called 'lazy'), you can do so:

    root/couchdb/views/users/lazy/*.js

There's a handy generator:

    script/generate couch_view users by_created_at
    script/generate couch_view users/lazy by_birthday
    script/generate couch_view users by_created_on map reduce

Thor tasks apply the views on the file system to CouchDb, skipping views that aren't dirty:

    thor ct:push

You can also view the differences between the views in CouchDb and those on the file system:

    thor ct:diff

###Remove dynamically generated views
We almost always need to write JavaScript to get the view behavior we need, and, for both conceptual and implementation complexity reasons, we value having all the views contained in one place--the file system. This also simplifies deployment and collaboration workflows.

###Multiple design documents per database
CouchDB supports multiple design documents per database. There's an important semantic consideration: all views in a design document are updated if any one view needs to be updated. To improve the read performance of couch views under high-volume reads and writes, you could organize views that don't need to be as timely into a separate design document named 'lazy', and always include the `stale=true` couch option in queries to views defined in the 'lazy' design document. You could then have a script that ran periodically to trigger the 'lazy' views to update.

    class UserDb > CouchTomato::Database
      name :users
      
      view :by_created_at, User
      view :count # raw
      view 'lazy/count_created_by_date'
    end

###Migrations
Couch Tomato migrations are similar to ActiveRecord migrations, however, Couch Tomato migrations modify existing fields of documents instead of a "schema". There is a handy generator available for migrators as well.

    script/generate couch_migration users by_created_at

Migration come with two methods, up and down, each with a document hash. Up/down method will be run on every document in a database, with changes to the document hash committed to a database if the method does not return false. A migration can be accessed by thor ct:migrate and the -v (version) option. The version is simply the prefixed number in front of the generated view file.

##Thor Tasks
All Thor tasks associated with Couch Tomato are available under the namespace "ct". The `-e` option specifies an environment (i.e. for Rails)

###ct:init
The init task creates the folder structure required for managing views and migrations and a sample `couch_tomato.yml`.

Example:

    thor ct:init

###ct:push
The push tasks syncs CouchDB with the view structure present on the file system.

Example:

    thor ct:push -e development
  
###ct:diff
The diff tasks `git status` type diff between the filesystem view structure and the current structure in CouchDB. The diff is with respect to the file system, that is, the file system is always assumed to be the most up to date.

Example:

    thor ct:diff -e development
  
###ct:drop
The drop task will remove a specified database within the given environment from CouchDB. The -r option can be specified to remove via regex, and no arguments can be supplied to remove all databases.

Examples:

    # Remove all databases (you will be prompted first)
    thor ct:drop -e development

    # Remove all databases ending "\_bak"
    thor ct:drop -e development -r .*\_bak

###ct:migrate
The migrate tasks runs migrations from your `couchdb/migrate` folder.

Examples:

    # Apply all migrations
    thor ct:migrate -e development
    
    # Undo migration "20090911201227"
    thor ct:migrate -e development --down -v 20090911201227
    
    # Redo the last 5 migrations
    thor ct:migrate -e development --redo -s 5
    
    # Reset all databases using all available migrations to the "development" environment
    thor ct:migrate -e development --reset

###ct:rollback
The rollback tasks will revert to a previous migration from the current version. Specify the number of steps with the -s option.

Examples:

    # Undo the previous migration
    thor ct:rollback -e development
    
    # Undo the last 5 migrations
    thor ct:rollback -e development -s 5

###ct:forward
The forward task will roll forward to the next version. Specify the number of steps with the -s option.

Example:

    # Roll forward to the next migration
    thor ct:forward -e development

###ct:replicate
The replicate task facilitates the duplication of databases across application environments. The source and target server are always required for replication. Replicate operates in three different functions:

1. If a source and destination database are provided, then the source database from the source server will be copied onto the destination database on the target server. Note that the destination database needs to already have been created.
2. If not 1., but the the source and target servers are the same, then all databases on the common server are duplicated; the duplicate databases are postfixed with a "\_bak".
3. If neither 1. or 2., then the assumption is that the user wants to clone all databases from the remote source server onto the specified target server.

Examples:

    # Copy database "example" from source server "11.11.11.11" to "example_1" in localhost
    thor ct:replicate -e development -s 11.11.11.11 -t localhost -c example -v example_1
    
    # Back up all databases in localhost
    thor ct:replicate -e development -s localhost -t localhost
    
    # Duplicate databases from "11.11.11.11" to localhost
    thor ct:replicate -e development -s 11.11.11.11 -t localhost

###ct:touch
The touch task will initiate the building of views for a given database. Touch will query the first view of the each design doc in a db which will cause all remaining views to be built as well.

Examples:

    # Build all design documents in databases "example" and "test"
    thor ct:touch -e development -d example test
    
    # Build all design documents in "example" and specify a 24 hours timeout
    thor ct:touch -e development -d example -t 86400
    
    # Build all design documents in "example" asynchronously
    thor ct:touch -e development -d example --async
    