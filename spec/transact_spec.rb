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
        '<JOB_ID>499600</JOB_ID>'+
        '<FILE_PATH>'+
          '/download/file.csv'+
        '</FILE_PATH>'+
      '</RESULT></Body></Envelope>'
    end

    it "send xml request" do
      stub_request(:post, url).with(:body => request,
              :headers => {'Accept'=>'*/*', 'Content-Type'=>'text/xml'}).
         to_return(:status => 200, :body => "", :headers => {})

      @transact = Transact.new("")
      @transact.query
    end
  end
end