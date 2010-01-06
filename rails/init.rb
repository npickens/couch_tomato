# this is for rails only
#::CouchConfig = ConfigHash.new(YAML.load_file("#{Rails.root}/config/couch_tomato.yml")[Rails.env] || {}) rescue nil

require File.dirname(__FILE__) + '/../lib/couch_tomato'
RAILS_DEFAULT_LOGGER.info "** couch_tomato: initialized from #{__FILE__}"
