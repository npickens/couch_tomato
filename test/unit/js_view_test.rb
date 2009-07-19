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
        sha = gen_str(40)
        
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
          gen_str => {:map => { :content => gen_str, :sha1 => gen_str(40) },
                      :reduce => { :content => gen_str, :sha1 => gen_str(40) }},
          gen_str => {:map => { :content => gen_str, :sha1 => gen_str(40) },
                      :reduce => { :content => gen_str, :sha1 => gen_str(40) }}
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
  end
end