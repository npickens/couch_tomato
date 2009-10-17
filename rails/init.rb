# this is for rails only

require File.dirname(__FILE__) + '/../lib/couch_tomato'

# CouchTomato::Config.database_name = YAML::load(File.read(Rails.root.to_s + '/config/couchdb.yml'))[RAILS_ENV]

RAILS_DEFAULT_LOGGER.info "** couch_tomato: initialized from #{__FILE__}"
