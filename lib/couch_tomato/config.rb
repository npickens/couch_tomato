module CouchTomato
  class Config
    cattr_accessor :url
    cattr_accessor :prefix
    cattr_accessor :suffix

    @@url    = "http://127.0.0.1:5984"
    @@prefix = ""
    @@suffix = defined?(Rails) ? Rails.env : ""
  end
end
