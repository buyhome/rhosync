require File.join(File.dirname(__FILE__),'..','spec_helper')

describe "BulkDataJob" do
  it_should_behave_like "SpecBootstrapHelper"
  it_should_behave_like "SourceAdapterHelper"
  
  before(:each) do
    Rhosync.blackberry_bulk_sync = true
  end
  
  after(:each) do
    delete_data_directory
  end
  
  let(:mock_schema) { {"property" => { "name" => "string", "brand" => "string" }, "version" => "1.0"} }
  
  it "should create bulk data files from master document" do
    set_state('test_db_storage' => @data)
    docname = bulk_data_docname(@a.id,@u.id)
    expected = { @s_fields[:name] => @data,
      'FixedSchemaAdapter' => @data
    }
    data = BulkData.create(:name => docname,
      :state => :inprogress,
      :app_id => @a.id,
      :user_id => @u.id,
      :sources => [@s_fields[:name], 'FixedSchemaAdapter'])
    BulkDataJob.perform("data_name" => data.name)
    BulkDataJob.after_perform_x("data_name" => data.name)
    data = BulkData.load(docname)
    data.completed?.should == true
    verify_result(@s.docname(:md) => @data,@s.docname(:md_copy) => @data)
    validate_db(data,expected).should == true
    File.exists?(data.dbfile+'.rzip').should == true
    File.exists?(data.dbfile+'.gzip').should == true
    File.exists?(data.dbfile+'.hsqldb.data').should == true
    File.exists?(data.dbfile+'.hsqldb.data.gzip').should == true
    File.exists?(data.dbfile+'.hsqldb.script').should == true
    File.exists?(data.dbfile+'.hsqldb.properties').should == true
    path = File.join(File.dirname(data.dbfile),'tmp')
    FileUtils.mkdir_p path
    unzip_file("#{data.dbfile}.rzip",path)
    data.dbfile = File.join(path,File.basename(data.dbfile))
    validate_db(data,expected).should == true
  end
  
  it "should not create hsql db files if blackberry_bulk_sync is disabled" do
    Rhosync.blackberry_bulk_sync = false
    set_state('test_db_storage' => @data)
    docname = bulk_data_docname(@a.id,@u.id)
    data = BulkData.create(:name => docname,
      :state => :inprogress,
      :app_id => @a.id,
      :user_id => @u.id,
      :sources => [@s_fields[:name]])
    BulkDataJob.perform("data_name" => data.name)
    BulkDataJob.after_perform_x("data_name" => data.name)
    data = BulkData.load(docname)
    data.completed?.should == true
    verify_result(@s.docname(:md) => @data,@s.docname(:md_copy) => @data)
    validate_db(data,@s.name => @data).should == true
    File.exists?(data.dbfile+'.hsqldb.script').should == false
    File.exists?(data.dbfile+'.hsqldb.properties').should == false
  end

  it "should create sqlite data with source metadata" do
    set_state('test_db_storage' => @data)
    mock_metadata_method([SampleAdapter]) do
      docname = bulk_data_docname(@a.id,@u.id)
      data = BulkData.create(:name => docname,
        :state => :inprogress,
        :app_id => @a.id,
        :user_id => @u.id,
        :sources => [@s_fields[:name]])
      BulkDataJob.perform("data_name" => data.name)
      BulkDataJob.after_perform_x("data_name" => data.name)
      data = BulkData.load(docname)
      data.completed?.should == true
      verify_result(@s.docname(:md) => @data,
        @s.docname(:metadata) => {'foo'=>'bar'}.to_json,
        @s.docname(:md_copy) => @data)
      validate_db(data,@s.name => @data).should == true
    end
  end
  
  it "should create sqlite data with source schema" do
    set_state('test_db_storage' => @data)
    mock_schema_method([SampleAdapter]) do
      docname = bulk_data_docname(@a.id,@u.id)
      data = BulkData.create(:name => docname,
        :state => :inprogress,
        :app_id => @a.id,
        :user_id => @u.id,
        :sources => [@s_fields[:name]])
      BulkDataJob.perform("data_name" => data.name)
      BulkDataJob.after_perform_x("data_name" => data.name)
      data = BulkData.load(docname)
      data.completed?.should == true
      verify_result(@s.docname(:md) => @data, @s.docname(:md_copy) => @data)
      JSON.parse(Store.get_value(@s.docname(:schema))).should == mock_schema      
      validate_db(data,@s.name => @data).should == true
    end
  end
  
  it "should raise exception if hsqldata fails" do
    data = BulkData.create(:name => bulk_data_docname(@a.id,@u.id),
      :state => :inprogress,
      :app_id => @a.id,
      :user_id => @u.id,
      :sources => [@s_fields[:name]])
    lambda { BulkDataJob.create_hsql_data_file(data,Time.now.to_i.to_s) 
      }.should raise_error(Exception,"Error running hsqldata")
  end
  
  it "should delete bulk data if exception is raised" do
    lambda { 
      BulkDataJob.perform("data_name" => 'broken')
      BulkDataJob.after_perform_x("data_name" => data.name) }.should raise_error(Exception)
    Store.db.keys('bulk_data*').should == []
  end
  
  it "should delete bulk data if exception is raised" do
    data = BulkData.create(:name => bulk_data_docname('broken',@u.id),
      :state => :inprogress,
      :app_id => 'broken',
      :user_id => @u.id,
      :sources => [@s_fields[:name]])
    lambda { 
      BulkDataJob.perform("data_name" => data.name)
      BulkDataJob.after_perform_x("data_name" => data.name) }.should raise_error(Exception)
    Store.db.keys('bulk_data*').should == []
  end
end