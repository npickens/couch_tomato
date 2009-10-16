require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/../../lib/couch_potato.rb'

class JsViewTes < Test::Unit::TestCase
  context "A Javascript View class" do
    setup do
      unload_const('TestView')
      ::TestView = create_const(CouchPotato::JsViewSource)
      def gen_str(size=10)
        (0...size).map{ ('a'..'z').to_a[rand(26)] }.join
      end
      
      def gen_num(size=10)
        (0...size).map{ (0..9).to_a[rand(10)] }.join
      end
      
      def gen_alphanum(size=10)
        (0...size).map{ ((0..9).to_a + ('a'..'z').to_a)[rand(36)] }.join
      end
      
      def gen_path(size=4)
        "/" + Array.new(size).collect{ gen_str }.join("/")
      end
    end
        
    should "infer a single database name from the file system" do
      path = gen_path
      database = gen_str
      stub(TestView).path { path }
      stub(Dir).[](TestView.path + "/**") { ["#{path}/#{database}"] }
      assert_equal TestView.fs_database_names, [database]
    end
    
    should "get a single design doc from couch server" do
      name = gen_str
      mock(db = Object.new).get(anything, anything) {{
        "rows" => [{
          "doc" => {
            "_id"=>"_design/#{name}"
          }
        }]}
      }
      
      expected = { name.to_sym => { "_id"=>"_design/#{name}" } }
      assert_equal TestView.db_design_docs(db), expected
    end
    
    context "with views in the local filesystem" do
      setup do
        @path = gen_path
        
        class VirtualFile
          def initialize(content)
            @content = content
          end
          
          def read
            @content
          end
          
          def close
            @content = nil
          end
        end
      end
      
      should "raise an exception when an invalid javascript file path is provided for a local view" do
        assert_raise Errno::ENOENT do
          TestView.fs_view({}, "#{@path}/#{gen_str}-map.js")
        end
      end
      
      should "raise an exception when an empty hash is provided as a container for the local javascript" do
        mock(TestView).open(anything) { VirtualFile.new("") }
        assert_raise RuntimeError do
          TestView.fs_view({}, "#{@path}/#{gen_str}-map.js")
        end
      end
      
      should "raise an exception if a passed javascript does not contain a map or reduce tag" do
        mock(TestView).open(anything) { VirtualFile.new("") }
        assert_raise RuntimeError do
          TestView.fs_view({}, "#{@path}/#{gen_str}.js")
        end
      end
      
      should "create a proper hash containing the information from a single javascript (view) file" do
        content = gen_str
        view_name = gen_str
        view_type = "map"
        file_path = "#{@path}/#{view_name}-#{view_type}.js"
        sha = gen_alphanum(40)
        
        mock(TestView).open(anything) { VirtualFile.new(content) }
        mock(Digest::SHA1).hexdigest(anything) { sha }
        
        expected = { "views" => {
          view_name => {
            view_type => content,
            "sha1-#{view_type}" => sha
          }
        }}
        assert_equal TestView.fs_view({'views' => {}}, file_path), expected
      end
      
      should "properly accrue the views for a given design document/database(without any design docs)" do
        design_name = gen_str
        views = {
          gen_str => {:map => { :content => gen_str, :sha1 => gen_alphanum(40) },
                      :reduce => { :content => gen_str, :sha1 => gen_alphanum(40) }},
          gen_str => {:map => { :content => gen_str, :sha1 => gen_alphanum(40) },
                      :reduce => { :content => gen_str, :sha1 => gen_alphanum(40) }}
        }
        
        accrued_hash = {'views' => {}}
        views.each do |view_name, view_types|
          view_types.each do |type, view_data|
            stub(TestView).open { VirtualFile.new(view_data[:content]) }
            path = "#{@path}/#{design_name}/#{view_name}-#{type.to_s}.js"
            stub(Digest::SHA1).hexdigest { view_data[:sha1] }
            TestView.fs_view(accrued_hash, path)
          end
        end
        
        expected = {'views' => {}}
        views.each do |view_name, view_types|
          expected['views'][view_name] ||= {}
          view_types.each do |type, view_data|
            expected['views'][view_name][type.to_s] = view_data[:content]
            expected['views'][view_name]["sha1-#{type.to_s}"] = view_data[:sha1]
          end
        end
        assert_equal accrued_hash, expected
      end
    end
    
    context "with design documents in the local filesystem that need to be aggregated" do
      setup do
        @path = gen_path
        @db_name = gen_str
        stub(TestView).path { @path + "/" + @db_name }
        
        def assign_path(views, design_doc=nil)
          views.map do |view|
            [@path, @db_name, design_doc, view].compact.join("/")
          end
        end
      end
    
      should "get a hash of a design doc under a specific database with no design folders in the filesystem; no reduce functions" do
        view = gen_str
        view_components = ["#{view}-map.js"]

        stub(Dir).[](TestView.path + "/**") { assign_path(view_components) }
        fs_view_return = {
          "views"=> {
            "#{view}"=> {}
          }
        }
        
        stub(TestView).fs_view { fs_view_return }
        expected = { @db_name.to_sym => fs_view_return }
        assert_equal TestView.fs_design_docs(@db_name), expected
      end
      
      should "get a hash of a design doc under a specific database with no design folders in the filesystem; one reduce function" do
        view = gen_str
        view_components = ["#{view}-map.js", "#{view}-reduce.js"]
      
        stub(Dir).[](TestView.path + "/**") { assign_path(view_components) }
        fs_view_return = {
          "views"=> {
            "#{view}"=> { "reduce"=>gen_str, "map"=>gen_str }
          }
        }
          
        stub(TestView).fs_view { fs_view_return }
        expected = { @db_name.to_sym => fs_view_return }
        assert_equal TestView.fs_design_docs(@db_name), expected
      end
      
      should "raise an exception when a reduce view is given without a corresponding map view under a specific database with no design folders" do
        view = gen_str
        view_components = ["#{view}-reduce.js"]
      
        stub(Dir).[](TestView.path + "/**") { assign_path(view_components) }
        fs_view_return = {
          "views"=> {
            "#{view}"=> { "reduce"=>gen_str }
          }
        }
          
        stub(TestView).fs_view { fs_view_return }
        assert_raise RuntimeError do
          TestView.fs_design_docs(@db_name)
        end
      end

      should "get a hash of design docs under a specific database with multiple design folders" do
        design_names = [gen_str, gen_str]
        views = design_names.inject({}) do |doc_views, doc_name|
          view = gen_str
          doc_views.merge!(doc_name => ["#{view}-map.js", "#{view}-reduce.js"])
        end

        mock(Dir).[](TestView.path + "/**") { assign_path(design_names) }
        mock(Dir).[]("#{TestView.path}/#{design_names[0]}/*.js") { 
          assign_path(views[design_names[0]], design_names[0]) }
        mock(Dir).[]("#{TestView.path}/#{design_names[1]}/*.js") { 
          assign_path(views[design_names[1]], design_names[1]) }
          
        expected = {
          design_names[0].to_sym => {
            "views"=> {
              views[design_names[0]].first.split("-").first => 
                { "reduce"=>gen_str, "map"=>gen_str }
            }
          },
          design_names[1].to_sym => {
            "views"=> {
              views[design_names[1]].first.split("-").first => 
                { "reduce"=>gen_str, "map"=>gen_str }
            }
          }
        }
        
        stub(TestView).fs_view(anything, /#{design_names[0]}/) { expected[design_names[0].to_sym] }
        stub(TestView).fs_view(anything, /#{design_names[1]}/) { expected[design_names[1].to_sym] }
        
        assert_equal TestView.fs_design_docs(@db_name), expected
      end
    end
    
    context "with documents in either the filesystem, the database, or both" do
      setup do
        @path = gen_path
        @db_name = gen_str
        
        def gen_view_file(type)
          {
            type => gen_str,
            "sha1-#{type}" => gen_alphanum(40)
          }
        end
        
        def gen_view(name, elements)
          view = {name => {}}
          elements.each do |element|
            view[name].merge!(gen_view_file(element.to_s))
          end
          view
        end
        
        def gen_design_doc(id, views)
          design_doc = {
            "_id" => "_design/#{id}",
            "views" => {}
          }
          
          views.each do |view, types|
            design_doc["views"].merge!(gen_view(view, types))
          end
          design_doc
        end
        
        def gen_db_hash(seed=rand(5))
          design_docs = {}
          types = [:map, :reduce]
          (0..seed).each do
            views = {}
            (0..rand(seed)).each do
              views.merge!(gen_str => types[0, rand(types.length) + 1])
            end
            design_name = gen_str
            design_docs.merge!(design_name.to_sym => gen_design_doc(design_name, views))
          end
          design_docs
        end
      end
      
      should "delete a document from the database when the same document is found on the filesystem with no views" do
        databases = [ gen_str ]
        mock(TestView).fs_database_names { databases }
        db = Object.new
        stub(TestView).database! { db }
        fs_db = gen_db_hash(1)
        remote_db = fs_db.clone
        remote_db.values.each { |doc| doc.merge!("_rev" => gen_num) }
        fs_db[fs_db.keys.first]["views"] = {}
        
        mock(TestView).fs_design_docs(anything) { fs_db }
        mock(TestView).db_design_docs(anything) { remote_db }

        mock(db).delete_doc(anything) {}
        stub(db).save_doc {}
        
        TestView.push(true)
      end
      
      should "create an empty remote db if an empty db folder is found in the file system" do
        db = Object.new
        mock(TestView).fs_database_names { [gen_str] }
        mock(TestView).database!(anything) { db }
        
        fs_single_doc_name = gen_str
        fs_db = {
          fs_single_doc_name.to_sym => {
            "_id" => "_design/#{fs_single_doc_name}", 
            "views" => {}}
        }
        remote_db = gen_db_hash(2)
        remote_db.values.each { |doc| doc.merge!("_rev" => gen_num) }
        mock(TestView).fs_design_docs(anything) { fs_db }
        mock(TestView).db_design_docs(anything) { remote_db }
        dont_allow(db).delete_doc(anything) {}
        dont_allow(db).save_doc(anything) {}
        
        TestView.push(true)
      end
      
      should "not update documents on the server if both file system and server documents are identical" do
        db = Object.new
        mock(TestView).fs_database_names { [gen_str] }
        mock(TestView).database!(anything) { db }
        
        fs_db = gen_db_hash(1)
        remote_db = fs_db.clone
        remote_db.values.each { |doc| doc.merge!("_rev" => gen_num) }
        
        mock(TestView).fs_design_docs(anything) { fs_db }
        mock(TestView).db_design_docs(anything) { remote_db }
        dont_allow(db).delete_doc(anything) {}
        dont_allow(db).save_doc(anything) {}
        
        TestView.push(true)
      end
      
      should "properly added all new documents seen on the file system to the remote system." do
        db = Object.new
        mock(TestView).fs_database_names { [gen_str] }
        mock(TestView).database!(anything) { db }
        
        fs_db = gen_db_hash(2)
        remote_db = gen_db_hash(2)
        remote_db.values.each { |doc| doc.merge!("_rev" => gen_num) }
        
        mock(TestView).fs_design_docs(anything) { fs_db }
        mock(TestView).db_design_docs(anything) { remote_db }
        dont_allow(db).delete_doc(anything) {}
        mock(db).save_doc(anything).times(fs_db.length) {}
        
        TestView.push(true)
      end
    end
    
    should "properly read fs view, create a remote database\
        if necessary, and copy all the local views to the remote site (database)" do
      stub(TestView).path { "#{File.dirname(__FILE__)}/../../test/integration" }
      #TODO: Complete this integration test.
    end
  end
end