require 'spec_helper'
require 'support/ftp/server'
require 'webmock/rspec'
require 'rainbow'

module Silverpop

  INSTANCE = 5

  describe Transact do

    describe "Local tests" do

      before(:all) do
        Silverpop.configure do |config|
          config.setup_urls(INSTANCE)
          config.engage_username = "developmentapi@billfloat.com"
          config.engage_password = "b!llFl0at"
          config.engage_ftp_username = "developmentapi@billfloat.com"
          config.engage_ftp_password = "B1llFl0at"
        end
      end

      let(:url) { "https://transact#{INSTANCE}.silverpop.com/XTMail" }
      
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

        transact = Transact.new("")
        transact.query
      end
    end
  end

  describe "Remote tests", :remote => true do

    before(:all) do
      WebMock.allow_net_connect!
        
      Silverpop.configure do |config|
        config.setup_urls(INSTANCE)
        config.engage_username = "developmentapi@billfloat.com"
        config.engage_password = "b!llFl0at"
        config.engage_ftp_username = "developmentapi@billfloat.com"
        config.engage_ftp_password = "B1llFl0at"
      end
    end

    it "create compaign" do
      puts "\n"
      puts "**********************************************************".color(:blue).background(:yellow)
      puts "            ATTENTION !!!                                 ".color(:blue).background(:yellow)
      puts " for the current moment the test for transact doesn't work".color(:blue).background(:yellow)
      puts "**********************************************************".color(:blue).background(:yellow)

      recipient = { 
        :email => 'test@test.com', 
        :personalizations => [
          {:tag_name => 'FIRST_NAME', :value => 'Joe'},
          {:tag_name => 'LAST_NAME',  :value => 'Schmoe'}
      ] }

      recipients = [  
        recipient,
        { :email => 'test2@test.com',
            :personalizations => [
              {:tag_name => 'FIRST_NAME', :value => 'John'},
              {:tag_name => 'LAST_NAME',  :value => 'Smith'}
        ] },
        { :email => 'test3@test.com',
            :personalizations => [
              {:tag_name => 'FIRST_NAME', :value => 'Jane'},
              {:tag_name => 'LAST_NAME',  :value => 'Doe'}
        ] } 
      ]
      campaign_id = 1234567
      
      transact = Silverpop::Transact.new campaign_id, recipients
      transact.query

      transact.should be_success
    end
  end
end