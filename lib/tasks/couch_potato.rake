namespace :couch_potato do
  desc 'Inserts the views into CouchDB'
  task :push => :environment do
    CouchPotato::JsViewSource.push
  end

  desc 'Compares views in DB and the File System'
  task :diff => :environment do
    CouchPotato::JsViewSource.diff
  end
end
