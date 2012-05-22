require File.join(File.dirname(__FILE__),'..','spec_helper')

describe "BulkData" do
  it_should_behave_like "SpecBootstrapHelper"
  it_should_behave_like "SourceAdapterHelper"
  
  before(:each) do
    @s = Source.load(@s_fields[:name],@s_params)
  end
  
  after(:each) do
    delete_data_directory
  end
  
  it "should return true if bulk data is completed" do
    dbfile = create_datafile(File.join(@a.name,@u.id.to_s),@u.id.to_s)
    data = BulkData.create(:name => bulk_data_docname(@a.id,@u.id),
      :state => :completed,
      :app_id => @a.id,
      :user_id => @u.id,
      :sources => [@s_fields[:name]])
    data.dbfile = dbfile 
    data.completed?.should == true
  end
  
  it "should return false if bulk data isn't completed" do
    data = BulkData.create(:name => bulk_data_docname(@a.id,@u.id),
      :state => :inprogress,
      :app_id => @a.id,
      :user_id => @u.id,
      :sources => [@s_fields[:name]])
    data.completed?.should == false
  end
  
  it "should expire_bulk_data from a source adapter" do
    adapter = SourceSync.new(@s).adapter
    time = Time.now.to_i + 10000
    data = BulkData.create(:name => bulk_data_docname(@a.id,@u.id),
      :state => :inprogress,
      :app_id => @a.id,
      :user_id => @u.id,
      :sources => [@s_fields[:name]],
      :refresh_time => time)
    adapter.expire_bulk_data
    data = BulkData.load(bulk_data_docname(@a.id,@u.id))
    data.refresh_time.should <= Time.now.to_i
  end
  
  it "should enqueue sqlite db type" do
    BulkData.enqueue
    Resque.peek(:bulk_data).should == {"args"=>[{}], 
      "class"=>"Rhosync::BulkDataJob"}
  end
  
  it "should generate correct bulk data name for user partition" do
    BulkData.get_name(:user,@c.user_id).should == File.join(@a_fields[:name],@u_fields[:login],@u_fields[:login])
  end
  
  it "should generate correct bulk data name for app partition" do
    BulkData.get_name(:app,@c.user_id).should == 
      File.join(@a_fields[:name],@a_fields[:name])
  end

  it "should have ordered sources list by priority" do
    data = BulkData.create(:name => bulk_data_docname(@a.id,@u.id),
      :state => :inprogress,
      :app_id => @a.id,
      :user_id => @u.id,
      :sources => @a.partition_sources(:user, @u.id))
    data.sources[0, -1].should == ["SampleAdapter", "FixedSchemaAdapter"]
    p1 = Source.load("SampleAdapter", {:app_id => data.app_id, :user_id => data.user_id}).priority
    p2 = Source.load("FixedSchemaAdapter", {:app_id => data.app_id, :user_id => data.user_id}).priority
    p1.should < p2
  end
  
  it "should process_sources for bulk data" do
    current = Time.now.to_i
    @s.read_state.refresh_time = current
    data = BulkData.create(:name => bulk_data_docname(@a.id,@u.id),
      :state => :inprogress,
      :app_id => @a.id,
      :user_id => @u.id,
      :sources => [@s_fields[:name]])
    data.process_sources
    @s.read_state.refresh_time.should >= current + @s_fields[:poll_interval].to_i
  end
  
  it "should delete source masterdoc copy on delete" do
    set_state('test_db_storage' => @data)
    data = BulkData.create(:name => bulk_data_docname(@a.id,@u.id),
      :state => :inprogress,
      :app_id => @a.id,
      :user_id => @u.id,
      :sources => [@s_fields[:name]])
    data.process_sources
    verify_result(@s.docname(:md_copy) => @data)
    data.delete
    verify_result(@s.docname(:md_copy) => {},
      @s.docname(:md) => @data)
  end
end

def create_datafile(dir,name)
  dir = File.join(Rhosync.data_directory,dir)
  FileUtils.mkdir_p(dir)
  fname = File.join(dir,name+'.data')
  File.open(fname,'wb') {|f| f.puts ''}
  fname
end