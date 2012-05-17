require 'rubygems'
require 'rhosync'
include Rhosync
ENV['RACK_ENV'] = 'test'

ERROR = '0_broken_object_id' unless defined? ERROR

module TestHelpers
  def get_testapp_path
    File.expand_path(File.join(File.dirname(__FILE__),'apps','rhotestapp'))
  end
  
  def do_post(url,params)
    post url, params.to_json, {'CONTENT_TYPE'=>'application/json'}
  end
  
  def bulk_data_docname(app_id,user_id)
    if user_id == "*"
      File.join(app_id,app_id)
    else
      File.join(app_id,user_id,user_id)
    end
  end
  
  def dump_db_data(store)
    puts "*"*50 
    puts "DATA DUMP"
    puts "*"*50
    store.db.keys('*').sort.each do |key|
      next if not key =~ /md|cd/ 
      line = ""
      line << "#{key}: "
      type = store.db.type key
      if type == 'set'
        if not key =~ /sources|clients|users/
          line << "#{store.get_data(key).inspect}"
        else
          line << "#{store.db.smembers(key).inspect}"
        end  
      else
        line << "#{store.db.get key}"
      end
      puts line
    end
    puts "*"*50
  end
  
  def add_client_id(data)
    res = Marshal.load(Marshal.dump(data))
    res.each { |key,value| value['rhomobile.rhoclient'] = @c.id.to_s }
  end

  def add_error_object(data,error_message,error_name='wrongname')
    error = {'an_attribute'=>error_message,'name'=>error_name} 
    data.merge!({ERROR=>error})
    data
  end
  
  def delete_data_directory
    FileUtils.rm_rf(Rhosync.data_directory)
  end
  
  def json_clone(data)
    JSON.parse(data.to_json)
  end
      
  def set_state(state)
    state.each do |dockey,data|
      if data.is_a?(Hash) or data.is_a?(Array)
        Store.put_data(dockey,data)
      else
        Store.put_value(dockey,data)
      end
    end
  end
  
  def set_test_data(dockey,data,error_message=nil,error_name='wrongname')
    if error_message
      error = {'an_attribute'=>error_message,'name'=>error_name} 
      data.merge!({ERROR=>error})
    end  
    Store.put_data(dockey,data)
    data
  end
  
  def verify_result(result)
    result.keys.sort.each do |dockey|
      expected = result[dockey]
      begin
        if expected.is_a?(Hash)
          Store.get_data(dockey).should == expected
        elsif expected.is_a?(Array)
          Store.get_data(dockey,Array).should == expected
        else
          Store.get_value(dockey).should == expected
        end
      rescue Spec::Expectations::ExpectationNotMetError => e
        message = "\nVerifying `#{dockey}`\n\n" + e.to_s
        Kernel::raise(Spec::Expectations::ExpectationNotMetError.new(message))
      end
    end
  end
  
  def validate_db(bulk_data,data)
    validate_db_file(bulk_data.dbfile,bulk_data.sources[0, -1],data)  
  end
    
  def validate_db_file(dbfile,sources,data)  
    db = SQLite3::Database.new(dbfile)
    sources.each do |source_name|
      s = Source.load(source_name,{:app_id => APP_NAME,:user_id => @u.login})
      return false unless validate_db_by_name(db,s,data[s.name])
    end 
    true 
  end
  
  def validate_db_by_name(db,s,data)
    db.execute("select source_id,name,sync_priority,partition,sync_type,source_attribs,
      metadata,schema,blob_attribs,associations,last_inserted_size, backend_refresh_time
      from sources where name='#{s.name}'").each do |row|
      return false if row[0].to_s != s.source_id.to_s
      return false if row[1] != s.name
      return false if row[2].to_s != s.priority.to_s
      return false if row[3] != s.partition_type.to_s
      return false if row[4] != s.sync_type.to_s
      return false if row[5] != (s.schema ? "" : get_attrib_counter(data))
      return false if row[6] != s.get_value(:metadata)
      return false if row[7] != s.schema
      return false if row[8] != s.blob_attribs
      return false if row[9] != s.has_many
      return false if row[10] != s.get_value(:md_size).to_i
      return false if row[11] != s.read_state.refresh_time
    end

    data = json_clone(data)
    if s.schema
      schema = JSON.parse(s.schema)
      columns = ['object']
      schema['property'].each do |key,value|
        columns << key
      end
      db.execute("select #{columns.join(',')} from #{s.name}") do |row|
        obj = data[row[0]]
        columns.each_index do |i|
          next if i == 0
          return false if row[i] != obj[columns[i]]
        end
        data.delete(row[0])
      end
    else
      db.execute("select * from object_values where source_id=#{s.source_id}").each do |row|
        object = data[row[2]]
        return false if object.nil? or object[row[1]] != row[3] or row[0].to_s != s.source_id.to_s
        object.delete(row[1])
        data.delete(row[2]) if object.empty?
      end
    end
    data.empty?
  end
  
  def get_attrib_counter(data)
    counter = {}
    data.each do |object_name,object|
      object.each do |attrib,value|
        counter[attrib] = counter[attrib] ? counter[attrib] + 1 : 1
      end
    end
    BulkDataJob.refs_to_s(counter)
  end
  
  def mock_metadata_method(adapters, &block)
    adapters.each do |klass|
      klass.class_eval "def metadata; {'foo'=>'bar'}.to_json; end"
    end
    yield
    adapters.each do |klass|
      klass.class_eval "def metadata; end"
    end
  end
  
  def mock_schema_method(adapters, &block)
    adapters.each do |klass|
      klass.class_eval 'def schema
        {
          "property" => {
            "name" => "string",
            "brand" => "string"
          },
          "version" => "1.0"
        }.to_json
      end'
    end
    yield
    adapters.each do |klass|
      klass.class_eval "def schema; end"
    end
  end
  
  def mock_schema_no_version_method(adapters, &block)
    adapters.each do |klass|
      klass.class_eval 'def schema
        {
          "property" => {
            "name" => "string",
            "brand" => "string"
          }
        }.to_json
      end'
    end
    yield
    adapters.each do |klass|
      klass.class_eval "def schema; end"
    end
  end

  def unzip_file(file,file_dir)
    Zip::ZipFile.open(file) do |zip_file|
      zip_file.each do |f|
        f_path = File.join(file_dir,f.name)
        FileUtils.mkdir_p(File.dirname(f_path))
        zip_file.extract(f, f_path) { true }
      end
    end
  end

  def get_sha1(str)
    Digest::SHA1.hexdigest(str)
  end  
  
end #TestHelpers

describe "RhosyncHelper", :shared => true do
  before(:each) do
    Store.create
    Store.db.flushdb
    # Source.delete_all # TODO: should have this
  end
end

describe "TestappHelper", :shared => true do
  include TestHelpers
  before(:all) do
    @test_app_name = 'application'
  end
end

describe "RhosyncDataHelper", :shared => true do  
  it_should_behave_like "RhosyncHelper"
  it_should_behave_like "TestappHelper"
  
  before(:each) do
    @source = 'Product'
    @user_id = 5
    @client_id = 1
    
    @product1 = {
      'name' => 'iPhone',
      'brand' => 'Apple',
      'price' => '199.99'
    }
    
    @product2 = {
      'name' => 'G2',
      'brand' => 'Android',
      'price' => '99.99'
    }

    @product3 = {
      'name' => 'Fuze',
      'brand' => 'HTC',
      'price' => '299.99'
    }
    
    @product4 = {
      'name' => 'Droid',
      'brand' => 'Android',
      'price' => '249.99'
    }
    
    @data = {'1'=>@product1,'2'=>@product2,'3'=>@product3}
  end
end  

describe "DBObjectsHelper", :shared => true do
  include TestHelpers
  
  before(:each) do
    @a_fields = { :name => @test_app_name }
    # @a = App.create(@a_fields)
    @a = (App.load(@test_app_name) || App.create(@a_fields))
    @u_fields = {:login => 'testuser'}
    @u = User.create(@u_fields) 
    @u.password = 'testpass'
    @c_fields = {
      :device_type => 'Apple',
      :device_pin => 'abcd',
      :device_port => '3333',
      :user_id => @u.id,
      :app_id => @a.id 
    }
    @s_fields = {
      :name => 'SampleAdapter',
      :url => 'http://example.com',
      :login => 'testuser',
      :password => 'testpass',
    }
    @s1_fields = {
      :name => 'FixedSchemaAdapter',
      :url => 'http://example.com',
      :login => 'testuser',
      :password => 'testpass',
    }
    @s_params = {
      :user_id => @u.id,
      :app_id => @a.id
    }
    @c = Client.create(@c_fields,{:source_name => @s_fields[:name]})
    @s = Source.create(@s_fields,@s_params)
    @s1 = Source.create(@s1_fields,@s_params)
    @s1.belongs_to = [{'brand' => 'SampleAdapter'}].to_json    
    config = Rhosync.source_config["sources"]['FixedSchemaAdapter']
    @s1.update(config)
    @r = @s.read_state
    @a.sources << @s.id
    @a.sources << @s1.id
    Source.update_associations(@a.sources.members)
    @a.users << @u.id
  end
end

describe "SourceAdapterHelper", :shared => true do
  it_should_behave_like "RhosyncDataHelper"
  it_should_behave_like "DBObjectsHelper"
end

describe "StorageStateHelper", :shared => true do
  it_should_behave_like "SourceAdapterHelper"
  
  before(:each) do
    @s.name = 'StorageStateAdapter'
  end
end

describe "SpecBootstrapHelper", :shared => true do
  it_should_behave_like "TestappHelper"
  before(:all) do
    Rhosync.bootstrap(get_testapp_path) do |rhosync|
      rhosync.vendor_directory = File.join(File.dirname(__FILE__),'..','vendor')
    end
  end
end