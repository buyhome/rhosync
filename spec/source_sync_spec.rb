require File.join(File.dirname(__FILE__),'spec_helper')

describe "SourceSync" do
  it_should_behave_like "SpecBootstrapHelper"
  it_should_behave_like "SourceAdapterHelper"
  
  before(:each) do
    @s = Source.load(@s_fields[:name],@s_params)
    @ss = SourceSync.new(@s)
  end
  
  let(:mock_schema) { {"property" => { "name" => "string", "brand" => "string" }, "version" => "1.0"} }

  it "should create SourceSync" do
    @ss.adapter.is_a?(SampleAdapter).should == true
  end
  
  it "should fail to create SourceSync with InvalidArgumentError" do
    lambda { SourceSync.new(nil) }.should raise_error(InvalidArgumentError, 'Invalid source')
  end
  
  it "should raise SourceAdapterLoginException if login fails" do
    msg = "Error logging in"
    @u.login = nil
    @ss = SourceSync.new(@s)
    @ss.should_receive(:log).with("SourceAdapter raised login exception: #{msg}")
    @ss.process_query
    verify_result(@s.docname(:errors) => {'login-error'=>{'message'=>msg}})
  end
  
  it "should raise SourceAdapterLogoffException if logoff fails" do
    msg = "Error logging off"
    @ss.should_receive(:log).with("SourceAdapter raised logoff exception: #{msg}")
    set_test_data('test_db_storage',{},msg,'logoff error')
    @ss.process_query
    verify_result(@s.docname(:errors) => {'logoff-error'=>{'message'=>msg}})
  end
  
  it "should hold on read on subsequent call of process" do
    expected = {'1'=>@product1}
    Store.put_data('test_db_storage',expected)
    @ss.process_query
    Store.put_data('test_db_storage',{'2'=>@product2})
    @ss.process_query
    verify_result(@s.docname(:md) => expected)   
  end
  
  it "should read on every subsequent call of process" do
    expected = {'2'=>@product2}
    @s.poll_interval = 0
    Store.put_data('test_db_storage',{'1'=>@product1})
    @ss.process_query
    Store.put_data('test_db_storage',expected)
    @ss.process_query
    verify_result(@s.docname(:md) => expected)    
  end
  
  it "should never call read on any call of process" do
    @s.poll_interval = -1
    Store.put_data('test_db_storage',{'1'=>@product1})
    @ss.process_query
    verify_result(@s.docname(:md) => {})
  end
    
  describe "methods" do
    
    it "should process source adapter" do
      mock_metadata_method([SampleAdapter, SimpleAdapter]) do
        expected = {'1'=>@product1,'2'=>@product2}
        set_state('test_db_storage' => expected)
        @ss.process_query
        verify_result(@s.docname(:md) => expected,
          @s.docname(:metadata) => "{\"foo\":\"bar\"}",
          @s.docname(:metadata_sha1) => "a5e744d0164540d33b1d7ea616c28f2fa97e754a")
      end
    end
    
    it "should process source adapter schema" do
      mock_schema_method([SampleAdapter]) do
        expected = {'1'=>@product1,'2'=>@product2}
        set_state('test_db_storage' => expected)
        @ss.process_query
        verify_result(@s.docname(:md) => expected)
        JSON.parse(Store.get_value(@s.docname(:schema))).should == mock_schema
        Store.get_value(@s.docname(:schema_sha1)) == get_sha1(mock_schema.to_json)
      end
    end
    
    it "should process source adapter with stash" do
      expected = {'1'=>@product1,'2'=>@product2}
      set_state('test_db_storage' => expected)
      #@ss.adapter.should_receive(:stash_result).once
      @ss.process_query('stash_result' => true)
      verify_result(@s.docname(:md) => expected,
        @s.docname(:md_size) => expected.size.to_s)
    end
    
    it "should call methods in source adapter" do
      mock_metadata_method([SampleAdapter, SimpleAdapter]) do
        expected = {'1'=>@product1,'2'=>@product2}
        metadata = "{\"foo\":\"bar\"}"
        @ss.adapter.should_receive(:login).once.with(no_args()).and_return(true)
        @ss.adapter.should_receive(:metadata).once.with(no_args()).and_return(metadata)
        @ss.adapter.should_receive(:query).once.with(no_args()).and_return(expected)
        @ss.adapter.should_receive(:sync).once.with(no_args()).and_return(true)
        @ss.adapter.should_receive(:logoff).once.with(no_args()).and_return(nil)
        @ss.process_query
      end
    end
    
    describe "create" do
      it "should do create where adapter.create returns nil" do
        set_state(@c.docname(:create) => {'2'=>@product2})
        @ss.create(@c.id)
        verify_result(@c.docname(:create_errors) => {},
          @c.docname(:create_links) => {},
          @c.docname(:create) => {})
      end
    
      it "should do create where adapter.create returns object link" do
        @product4['link'] = 'test link'
        set_state(@c.docname(:create) => {'4'=>@product4})
        @ss.create(@c.id)
        verify_result(@c.docname(:create_errors) => {},
          @c.docname(:create_links) => {'4'=>{'l'=>'backend_id'}},
          @c.docname(:create) => {})
      end
    
      it "should raise exception on adapter.create" do
        msg = "Error creating record"
        data = add_error_object({'4'=>@product4,'2'=>@product2},msg)
        set_state(@c.docname(:create) => data)
        @ss.create(@c.id)
        verify_result(@c.docname(:create_errors) => 
          {"#{ERROR}-error"=>{"message"=>msg},ERROR=>data[ERROR]})
      end
    end
    
    describe "update" do
      it "should do update with no errors" do
        set_state(@c.docname(:update) => {'4'=> { 'price' => '199.99' }})
        @ss.update(@c.id)
        verify_result(@c.docname(:update_errors) => {},
          @c.docname(:update) => {})
      end
      
      it "should do update with errors" do
        msg = "Error updating record"
        data = add_error_object({'4'=> { 'price' => '199.99' }},msg)
        set_state(@c.docname(:update) => data,
          @c.docname(:cd) => { ERROR => { 'price' => '99.99' } }
        )
        @ss.update(@c.id)
        verify_result(
          @c.docname(:update_errors) =>
            {"#{ERROR}-error"=>{"message"=>msg}, ERROR=>data[ERROR]},
          @c.docname(:update_rollback) => {ERROR=>{"price"=>"99.99"}})
      end
    end
    
    describe "delete" do
      it "should do delete with no errors" do
        set_state(@c.docname(:delete) => {'4'=>@product4},
          @s.docname(:md) => {'4'=>@product4,'3'=>@product3},
          @c.docname(:cd) => {'4'=>@product4,'3'=>@product3})
        @ss.delete(@c.id)
        verify_result(@c.docname(:delete_errors) => {},
          @s.docname(:md) => {'3'=>@product3},
          @c.docname(:cd) => {'3'=>@product3},
          @c.docname(:delete) => {})
      end
      
      it "should do delete with errors" do
        msg = "Error delete record"
        data = add_error_object({'2'=>@product2},msg)
        set_state(@c.docname(:delete) => data)
        @ss.delete(@c.id)
        verify_result(@c.docname(:delete_errors) => {"#{ERROR}-error"=>{"message"=>msg}, ERROR=>data[ERROR]})
      end
    end
    
    describe "cud" do
      it "should do process_cud" do
        @ss.should_receive(:_auth_op).twice.and_return(true)
        @ss.should_receive(:create).once.with(@c.id)
        @ss.should_receive(:update).once.with(@c.id)
        @ss.should_receive(:delete).once.with(@c.id)
        @ss.process_cud(@c.id)
      end
    end
    
    describe "query" do
      it "should do query with no exception" do
        verify_read_operation('query')
      end
      
      it "should do query with exception raised" do
        verify_read_operation_with_error('query')
      end
    end
    
    describe "search" do
      it "should do search with no exception" do
        verify_read_operation('search')
      end
      
      it "should do search with exception raised" do
        verify_read_operation_with_error('search')
      end
      
      it "should do query with exception raised and update refresh time only after retries limit is exceeded" do
        @s.retry_limit = 1
        msg = "Error during query"
        set_test_data('test_db_storage',{},msg,"query error")
        res = @ss.do_query
        verify_result(@s.docname(:md) => {},
          @s.docname(:errors) => {'query-error'=>{'message'=>msg}})
        # 1) if retry_limit is set to N - then, first N retries should not update refresh_time
        @s.read_state.retry_counter.should == 1
        @s.read_state.refresh_time.should <= Time.now.to_i

        # try once more and fail again
        set_test_data('test_db_storage',{},msg,"query error")
        res = @ss.do_query
        verify_result(@s.docname(:md) => {},
          @s.docname(:errors) => {'query-error'=>{'message'=>msg}})

        # 2) if retry_limit is set to N and number of retries exceeded it - update refresh_time
        @s.read_state.retry_counter.should == 0
        @s.read_state.refresh_time.should > Time.now.to_i
      end
      
      it "should do query with exception raised and restore state with succesfull retry" do
        @s.retry_limit = 1
        msg = "Error during query"
        set_test_data('test_db_storage',{},msg,"query error")
        res = @ss.do_query
        verify_result(@s.docname(:md) => {},
          @s.docname(:errors) => {'query-error'=>{'message'=>msg}})
        # 1) if retry_limit is set to N - then, first N retries should not update refresh_time
        @s.read_state.retry_counter.should == 1
        @s.read_state.refresh_time.should <= Time.now.to_i

        # try once more (with success)
        expected = {'1'=>@product1,'2'=>@product2}
        set_test_data('test_db_storage',expected)
        @ss.do_query 
        verify_result(@s.docname(:md) => expected, 
          @s.docname(:errors) => {})
        @s.read_state.retry_counter.should == 0
        @s.read_state.refresh_time.should > Time.now.to_i
      end

      it "should reset the retry counter if prev_refresh_time was set more than poll_interval secs ago" do
        @s.retry_limit = 3
        @s.poll_interval = 2
        msg = "Error during query"
        set_test_data('test_db_storage',{},msg,"query error")
        res = @ss.do_query
        verify_result(@s.docname(:md) => {},
          @s.docname(:errors) => {'query-error'=>{'message'=>msg}})
        # 1) if retry_limit is set to N - then, first N retries should not update refresh_time
        @s.read_state.retry_counter.should == 1
        @s.read_state.refresh_time.should <= Time.now.to_i

        # 2) Make another error - results are the same
        set_test_data('test_db_storage',{},msg,"query error")
        res = @ss.do_query
        verify_result(@s.docname(:md) => {},
          @s.docname(:errors) => {'query-error'=>{'message'=>msg}})
        # 1) if retry_limit is set to N - then, first N retries should not update refresh_time
        @s.read_state.retry_counter.should == 2
        @s.read_state.refresh_time.should <= Time.now.to_i

        # wait until time interval exprires and prev_refresh_time is too old - 
        # this should reset the counter on next request with error
        # and do not update refresh_time
        sleep(3)
        set_test_data('test_db_storage',{},msg,"query error")
        res = @ss.do_query
        verify_result(@s.docname(:md) => {},
          @s.docname(:errors) => {'query-error'=>{'message'=>msg}})
        @s.read_state.retry_counter.should == 1
        @s.read_state.refresh_time.should <= Time.now.to_i
      end

      it "should do query with exception raised and update refresh time if retry_limit is 0" do
        @s.retry_limit = 0
        msg = "Error during query"
        set_test_data('test_db_storage',{},msg,"query error")
        res = @ss.do_query
        verify_result(@s.docname(:md) => {},
          @s.docname(:errors) => {'query-error'=>{'message'=>msg}})
        #  if poll_interval is set to 0 - refresh time should be updated
        @s.read_state.retry_counter.should == 0
        @s.read_state.refresh_time.should > Time.now.to_i
      end

      it "should do query with exception raised and update refresh time if poll_interval == 0" do
        @s.retry_limit = 1
        @s.poll_interval = 0
        msg = "Error during query"
        set_test_data('test_db_storage',{},msg,"query error")
        prev_refresh_time = @s.read_state.refresh_time
        # make sure refresh time is expired
        sleep(1)
        res = @ss.do_query
        verify_result(@s.docname(:md) => {},
          @s.docname(:errors) => {'query-error'=>{'message'=>msg}})
        #  if poll_interval is set to 0 - refresh time should be updated
        @s.read_state.retry_counter.should == 0
        @s.read_state.refresh_time.should > prev_refresh_time
      end
    end
    
    describe "app-level partitioning" do
      it "should create app-level masterdoc with '__shared__' docname" do
        @s1 = Source.load(@s_fields[:name],{:user_id => "testuser",:app_id => @a.id})
        @s1.partition = :app
        @ss1 = SourceSync.new(@s1)
        expected = {'1'=>@product1,'2'=>@product2}
        set_state('test_db_storage' => expected)
        @ss1.process_query
        verify_result("source:#{@test_app_name}:__shared__:#{@s_fields[:name]}:md" => expected)
        Store.db.keys("read_state:#{@test_app_name}:__shared__*").sort.should ==
          [ "read_state:#{@test_app_name}:__shared__:SampleAdapter:refresh_time",
            "read_state:#{@test_app_name}:__shared__:SampleAdapter:prev_refresh_time",
            "read_state:#{@test_app_name}:__shared__:SampleAdapter:retry_counter",
            "read_state:#{@test_app_name}:__shared__:SampleAdapter:rho__id"].sort
      end
    end
    
    def verify_read_operation(operation)
      expected = {'1'=>@product1,'2'=>@product2}
      set_test_data('test_db_storage',expected)
      Store.put_data(@s.docname(:errors),
        {"#{operation}-error"=>{'message'=>'failed'}},true)
      if operation == 'query'
        @ss.read.should == true
        verify_result(@s.docname(:md) => expected, 
          @s.docname(:errors) => {})
      else
        @ss.search(@c.id).should == true  
        verify_result(@c.docname(:search) => expected,
          @c.docname(:search_errors) => {})
      end
    end
    
    def verify_read_operation_with_error(operation)
      msg = "Error during #{operation}"
      @ss.should_receive(:log).with("SourceAdapter raised #{operation} exception: #{msg}")
      set_test_data('test_db_storage',{},msg,"#{operation} error")
      if operation == 'query'
        @ss.read.should == true
        verify_result(@s.docname(:md) => {},
          @s.docname(:errors) => {'query-error'=>{'message'=>msg}})
      else
        @ss.search(@c.id).should == true
        verify_result(@c.docname(:search) => {}, 
          @c.docname(:search_errors) => {'search-error'=>{'message'=>msg}})
      end
    end
  end
  
  it "should enqueue process_cud SourceJob" do
    @s.cud_queue = :cud
    @ss.process_cud(@c.id)
    Resque.peek(:cud).should == {"args"=>
      ["cud", @s.name, @a.name, @u.login, @c.id, nil], "class"=>"Rhosync::SourceJob"}
  end
  
  it "should enqueue process_query SourceJob" do
    @s.query_queue = :abc
    @ss.process_query({'foo'=>'bar'})
    Resque.peek(:abc).should == {"args"=>
      ["query", @s.name, @a.name, @u.login, nil, {'foo'=>'bar'}], "class"=>"Rhosync::SourceJob"}
  end
end