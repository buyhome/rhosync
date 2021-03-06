require File.join(File.dirname(__FILE__),'api_helper')

describe "RhosyncApiDeleteUser" do
  it_should_behave_like "ApiHelper" 
  
  it "should delete user" do
    params = {:api_token => @api_token,
       :attributes => {:login => 'testuser1', :password => 'testpass1'}}
     post "/api/create_user", params
     last_response.should be_ok
     User.is_exist?(params[:attributes][:login]).should == true

     #set up two users with data for the same source
     params2 = {:app_id => APP_NAME,:user_id => 'testuser1'}
     params3 = {:app_id => APP_NAME,:user_id => 'testuser'}
     s  = Source.load('SampleAdapter', params2)
     s2 = Source.load('SampleAdapter', params3)
     time = Time.now.to_i
     s.read_state.refresh_time = time
     s2.read_state.refresh_time = time
     set_state(s.docname(:delete) => {'4'=>@product4})
     set_state(s2.docname(:delete) => {'4'=>@product4})
     verify_result(s.docname(:delete) => {'4'=>@product4})
     verify_result(s2.docname(:delete) => {'4'=>@product4})


     post "/api/delete_user", {:api_token => @api_token, :user_id => params[:attributes][:login]}  
     last_response.should be_ok
     verify_result(s.docname(:delete) => {})
     verify_result(s2.docname(:delete) => {'4'=>@product4})
     s.load_read_state.should == nil
     s2.load_read_state.refresh_time.should == time
     User.is_exist?(params[:attributes][:login]).should == false
     App.load(APP_NAME).users.members.should == ["testuser"]
   
  end
end