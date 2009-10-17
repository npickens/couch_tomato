require File.dirname(__FILE__) + '/spec_helper'

# class Build
#   include CouchTomato::Persistence
# 
#   property :state
#   property :time
# 
#   view :timeline, :key => :time
#   view :count, :key => :time, :reduce => true
#   view :minimal_timeline, :key => :time, :properties => [:state], :type => :properties
#   view :key_array_timeline, :key => [:time, :state]
#   view :custom_timeline, :map => "function(doc) { emit(doc._id, {state: 'custom_' + doc.state}); }", :type => :custom
#   view :custom_timeline_returns_docs, :map => "function(doc) { emit(doc._id, null); }", :include_docs => true, :type => :custom
#   view :raw, :type => :raw, :map => "function(doc) {emit(doc._id, doc.state)}"
#   view :filtered_raw, :type => :raw, :map => "function(doc) {emit(doc._id, doc.state)}", :results_filter => lambda{|res| res['rows'].map{|row| row['value']}}
#   view :with_view_options, :group => true, :key => :time
# end
# 
# describe 'view' do
#   before(:each) do
#     recreate_db
#   end
# 
#   it "should return instances of the class" do
#     CouchTomato.database.save_document Build.new(:state => 'success', :time => '2008-01-01')
#     results = CouchTomato.database.view(Build.timeline)
#     results.map(&:class).should == [Build]
#   end
# 
#   it "should pass the view options to the view query" do
#     query = mock 'query'
#     CouchTomato::View::ViewQuery.stub!(:new).and_return(query)
#     query.should_receive(:query_view!).with(hash_including(:key => 1)).and_return('rows' => [])
#     CouchTomato.database.view Build.timeline(:key => 1)
#   end
# 
#   it "should not return documents that don't have a matching ruby_class" do
#     CouchTomato.couchrest_database.save_doc({:time => 'x'})
#     CouchTomato.database.view(Build.timeline).should == []
#   end
# 
#   it "should count documents" do
#     CouchTomato.database.save_document Build.new(:state => 'success', :time => '2008-01-01')
#     CouchTomato.database.view(Build.count(:reduce => true)).should == 1
#   end
# 
#   it "should count zero documents" do
#     CouchTomato.database.view(Build.count(:reduce => true)).should == 0
#   end
# 
#   describe "properties defined" do
#     it "should assign the configured properties" do
#       CouchTomato.couchrest_database.save_doc(:state => 'success', :time => '2008-01-01', :ruby_class => 'Build')
#       CouchTomato.database.view(Build.minimal_timeline).first.state.should == 'success'
#     end
# 
#     it "should not assign the properties not configured" do
#       CouchTomato.couchrest_database.save_doc(:state => 'success', :time => '2008-01-01', :ruby_class => 'Build')
#       CouchTomato.database.view(Build.minimal_timeline).first.time.should be_nil
#     end
# 
#     it "should assign the id even if it is not configured" do
#       id = CouchTomato.couchrest_database.save_doc(:state => 'success', :time => '2008-01-01', :ruby_class => 'Build')['id']
#       CouchTomato.database.view(Build.minimal_timeline).first._id.should == id
#     end
#   end
# 
#   describe "no properties defined" do
#     it "should assign all properties to the objects by default" do
#       id = CouchTomato.couchrest_database.save_doc({:state => 'success', :time => '2008-01-01', :ruby_class => 'Build'})['id']
#       result = CouchTomato.database.view(Build.timeline).first
#       result.state.should == 'success'
#       result.time.should == '2008-01-01'
#       result._id.should == id
#     end
#   end
# 
#   describe "map function given" do
#     it "should still return instances of the class" do
#       CouchTomato.couchrest_database.save_doc({:state => 'success', :time => '2008-01-01'})
#       CouchTomato.database.view(Build.custom_timeline).map(&:class).should == [Build]
#     end
# 
#     it "should assign the properties from the value" do
#       CouchTomato.couchrest_database.save_doc({:state => 'success', :time => '2008-01-01'})
#       CouchTomato.database.view(Build.custom_timeline).map(&:state).should == ['custom_success']
#     end
# 
#     it "should leave the other properties blank" do
#       CouchTomato.couchrest_database.save_doc({:state => 'success', :time => '2008-01-01'})
#       CouchTomato.database.view(Build.custom_timeline).map(&:time).should == [nil]
#     end
# 
#     describe "that returns null documents" do
#       it "should return instances of the class" do
#         CouchTomato.couchrest_database.save_doc({:state => 'success', :time => '2008-01-01'})
#         CouchTomato.database.view(Build.custom_timeline_returns_docs).map(&:class).should == [Build]
#       end
# 
#       it "should assign the properties from the value" do
#         CouchTomato.couchrest_database.save_doc({:state => 'success', :time => '2008-01-01'})
#         CouchTomato.database.view(Build.custom_timeline_returns_docs).map(&:state).should == ['success']
#       end
#     end
#   end
# 
#   describe "with array as key" do
#     it "should create a map function with the composite key" do
#       CouchTomato::View::ViewQuery.should_receive(:new).with(anything, anything, anything, string_matching(/emit\(\[doc\['time'\], doc\['state'\]\]/), anything).and_return(stub('view query').as_null_object)
#       CouchTomato.database.view Build.key_array_timeline
#     end
#   end
# 
#   describe "raw view" do
#     it "should return the raw data" do
#       CouchTomato.database.save_document Build.new(:state => 'success', :time => '2008-01-01')
#       CouchTomato.database.view(Build.raw)['rows'][0]['value'].should == 'success'
#     end
# 
#     it "should return filtred raw data" do
#       CouchTomato.database.save_document Build.new(:state => 'success', :time => '2008-01-01')
#       CouchTomato.database.view(Build.filtered_raw).should == ['success']
#     end
# 
#     it "should pass view options declared in the view declaration to the query" do
#      view_query = mock 'view_query'
#      CouchTomato::View::ViewQuery.stub!(:new).and_return(view_query)
#      view_query.should_receive(:query_view!).with(hash_including(:group => true)).and_return({'rows' => []})
#      CouchTomato.database.view(Build.with_view_options)
#     end
#   end
# 
# end