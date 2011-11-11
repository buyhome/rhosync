require File.join(File.dirname(__FILE__),'api_helper')

describe "RhosyncApiGetApiToken" do
  it_should_behave_like "ApiHelper"
  
  it "should get token string" do
    post "/login", :login => 'rhoadmin',:password => ''
    post "/api/get_api_token"
    last_response.body.should == @api_token
  end
  
  it "response should have cache-control and pragma headers set to no-cache" do
    post "/login", :login => 'rhoadmin',:password => ''
    last_response.headers['Cache-Control'].should == 'no-cache'
    last_response.headers['Pragma'].should == 'no-cache'
  end
  
  it "should fail to get token if user is not rhoadmin" do
    post "/login", :login => @u_fields[:login],:password => 'testpass'
    post "/api/get_api_token"
    last_response.status.should == 422    
    last_response.body.should == 'Invalid/missing API user'
  end  
  
  it "should return 422 if no token provided" do
    params = {:attributes => {:login => 'testuser1', :password => 'testpass1'}}
    post "/api/create_user", params
    last_response.status.should == 422
  end
end