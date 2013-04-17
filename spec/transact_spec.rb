require 'spec_helper'
require 'support/ftp/server'
require 'webmock/rspec'

module Silverpop

  describe Transact do

    before(:all) do
      Silverpop::Base.configure do |config|
        config.setup_urls(5)
        config.engage_username = "developmentapi@billfloat.com"
        config.engage_password = "b!llFl0at"
        config.engage_ftp_username = "developmentapi@billfloat.com"
        config.engage_ftp_password = "B1llFl0at"
      end
    end

    let(:pod) { 5 }
    let(:url) { "https://transact#{pod}.silverpop.com/XTMail" }
    
    let(:request) do 
      "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>\n<XTMAILING>\n<CAMPAIGN_ID></CAMPAIGN_ID>\n<SHOW_ALL_SEND_DETAIL>true</SHOW_ALL_SEND_DETAIL>\n<SEND_AS_BATCH>false</SEND_AS_BATCH>\n<NO_RETRY_ON_FAILURE>false</NO_RETRY_ON_FAILURE>\n</XTMAILING>"
    end
    
    let(:response) do
      '<Envelope><Body><RESULT>'+
        '<SUCCESS>TRUE</SUCCESS>'+
        '<USER_ID>12c734c-108b610e402-f528764d624db129b32c21fbca0cb8d6</USER_ID>'+
        '<NAME>Welcome Campaign</NAME>'+
        '<STATUS>Active</STATUS>'+
        '<NOTES>Mailings will be sent when subscription begins.</NOTES>'+
        '<LIST_ID>56432</LIST_ID>'+
        '<EVENT_TRIGGER>CustomEventDate</EVENT_TRIGGER>'+
        '<TRACKING_LEVEL>Unique</TRACKING_LEVEL>'+
        '<CUSTOM_EVENT_DATE_COLUMN>Magazine Subscription Date</CUSTOM_EVENT_DATE_COLUMN>'+
        '<ACTIVATION_DATE>01/29/2011</ACTIVATION_DATE>'+
        '<COMPLETION_DATE>12/31/2011</COMPLETION_DATE>'+
      '</RESULT></Body></Envelope>'
    end

    it "send xml request" do
      stub_request(:post, url).with(:body => request,
              :headers => {'Accept'=>'*/*', 'Content-Type'=>'text/xml'}).
         to_return(:status => 200, :body => response, :headers => {})

      @transact = Transact.new("")
      @transact.query
    end
  end
end