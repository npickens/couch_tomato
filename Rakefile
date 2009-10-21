require 'rubygems'

require 'test/unit'
require 'rake'
# require 'spec/rake/spectask'
require 'rake/testtask'
require 'rake/rdoctask'

require 'shoulda/tasks'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |s|
    s.name = "couch_tomato"
    s.summary = %Q{Ruby persistence layer for CouchDB, inspired by and forked from Couch Potato}
    s.email = "dev@plastictrophy.com"
    s.homepage = "http://github.com/plastictrophy/couch_tomato"
    s.description = "Ruby persistence layer for CouchDB, inspired by and forked from Couch Potato"
    s.authors = ["Plastic Trophy"]
    s.files = FileList["[A-Z]*.*", "{lib,rails,generators}/**/*", "init.rb"]
    s.add_dependency 'json'
    s.add_dependency 'validatable'
    s.add_dependency 'couchrest', '>=0.24'
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem install jeweler -s http://http://gemcutter.org"
end

Dir["#{File.dirname(__FILE__)}/tasks/*.rake"].sort.each { |ext| load ext }

task :default => :test

Rake::TestTask.new("test") do |t|
  t.libs << 'test' << "#{File.dirname(__FILE__)}/../lib"
  t.pattern = 'test/**/*_test.rb'
  # t.warning = true
  t.verbose = true
end

# task :default => :spec
#
# desc "Run all functional specs"
# Spec::Rake::SpecTask.new(:spec_functional) do |t|
#   t.spec_opts = ['--options', "\"#{File.dirname(__FILE__)}/spec/spec.opts\""]
#   t.spec_files = FileList['spec/*_spec.rb']
# end
#
# desc "Run all unit specs"
# Spec::Rake::SpecTask.new(:spec_unit) do |t|
#   t.spec_opts = ['--options', "\"#{File.dirname(__FILE__)}/spec/spec.opts\""]
#   t.spec_files = FileList['spec/unit/*_spec.rb']
# end
#
# desc "Run all specs"
#   task :spec => [:spec_unit, :spec_functional] do
# end