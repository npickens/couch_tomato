Couch Tomato
============

## TODO

### Documentation

- Quick start
- Data migration mechanism for managing (implicit) schema and data changes between team members and deployed systems, complete with generator and Rake tasks
- Rake tasks that facilitate replication of local and remote CouchDB databases
- Removed model property dirty tracking (added significant complexity and we haven't needed it...yet?)
- Shoulda instead of RSpec
- RR for mocks/stubs

### Code

- default "server" to `http://localhost:5984`


## Potato/Tomato

We're huge fans of Couch Potato. We love it's advocacy for using Couch naturally (not trying to make it look like a SQL database). Originally a Couch Potato fork, Couch Tomato supports our own production needs.

### Multi-Database Support

CouchDB makes it dead-simple to manage multiple databases. For large data-sets, it's very important to separate unrelated documents into separate databases. Couch Tomato assumes (but doesn't force) the use of multiple databases.

    class UserDb < CouchTomato::Database
      name "users"
      server "http://#{APP_CONFIG["couchdb_address"]}:#{APP_CONFIG["couchdb_port"]}"
    end

    class StatDb < CouchTomato::Database
      name "stats"
      server "http://#{APP_CONFIG["couchdb_address"]}:#{APP_CONFIG["couchdb_port"]}"
    end

    UserDb.save_doc(User.new({:name => 'Joe'}))
    5_000.times { StatDb.save_doc(Stat.new({:metric => 10_000 * rand})) }

### Each view determines the model for its values

Views return arbitrary hashes. Often a views' value is an entire document (or more correctly, utilize `emit(key, null)` combined with `:include_docs => true`). But, a views' value is also often completely independent of the structure of the underlying documents.

Define views on the database rather than inside a model (this is arguably more Couch-like). Each views declaration stipulates whether their results should be 'raw' hashes or a particular model type.

    class UserDb < CouchTomato::Database
      name "users"
      server "http://#{APP_CONFIG["couchdb_address"]}:#{APP_CONFIG["couchdb_port"]}"
      
      view :by_created_at, User
      view :count # raw
    end

### Store view definitions on the file system

Rather than having Ruby generate JavaScript or writing JavaScript in our Ruby code as a string, define views in files on the file system:

    RAILS_ROOT/couchdb/views/users/*-map.js
    RAILS_ROOT/couchdb/views/users/*-reduce.js
    
The reduce is optional. If you want to define views in a specific design document (called 'lazy'), you can do so:

    RAILS_ROOT/couchdb/views/users/lazy/*.js

There's a handy generator:

    script/generate view users by_created_at
    script/generate view users/lazy by_birthday
    script/generate view users by_created_on map reduce

Rake tasks apply the views on the file system to Couch, skipping views that aren't dirty:

    rake couch_tomato:push

You can also view the differences between the views in Couch and those on the file system:

    rake couch_tomato:diff

### Remove dynamically generated views

We almost always need to write JavaScript to get the view behavior we need, and, for both conceptual and implementation complexity reasons, we value having all the views contained in one place--the file system. This also simplifies deployment and collaboration workflows.

### Multiple design documents per database

CouchDB supports multiple design documents per database. There's an important semantic consideration: all views in a design document are updated if any one view needs to be updated. To improve the read performance of couch views under high-volume reads and writes, you could organize views that don't need to be as timely into a separate design document named 'lazy', and always include the `stale=true` couch option in queries to views defined in the 'lazy' design document. You could then have a script that ran periodically to trigger the 'lazy' views to update.

    class UserDb > CouchTomato::Database
      name :users
      
      view :by_created_at, User
      view :count # raw
      view 'lazy/count_created_by_date'
    end

We have not had a use for this, nor have we demonstrated that the claimed performance benefit actually exists (it originated from the CouchDB docs, wiki or list or some-such). But, it is instance where this approach to representing views maps fairly directly to CouchDB functionality.
