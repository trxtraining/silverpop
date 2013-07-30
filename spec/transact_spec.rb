require 'spec_helper'
require 'support/ftp/server'
require 'webmock/rspec'
require 'rainbow'
require 'nokogiri'

module Silverpop

  describe Transact do

    let (:recipient) do
      {
        :email => 'test@test.com',
        :personalizations => [
        {:tag_name => 'FIRST_NAME', :value => 'Joe'},
        {:tag_name => 'LAST_NAME',  :value => 'Schmoe'}]
      }
    end

    let(:recipients) do
      [ recipient,
        { :email => 'test2@test.com',
          :personalizations => [
              {:tag_name => 'FIRST_NAME', :value => 'John'},
              {:tag_name => 'LAST_NAME',  :value => 'Smith'}
          ] },
        { :email => 'test3@test.com',
          :personalizations => [
            {:tag_name => 'FIRST_NAME', :value => 'Jane'},
            {:tag_name => 'LAST_NAME',  :value => 'Doe'}
          ] }]
    end

    describe "Local tests" do

      before(:all) do
        Silverpop.configure do |config|
          config.setup_urls(ENV['ENGAGE_INSTANCE'])
          config.engage_username = ENV['ENGAGE_USERNAME']
          config.engage_password = ENV['ENGAGE_PASSWORD']
          config.engage_ftp_username = ENV['ENGAGE_FTP_USERNAME']
          config.engage_ftp_password = ENV['ENGAGE_FTP_PASSWORD']
        end
      end

      let(:transact) { Transact.new("")}

      let(:recipient_xml) do
        %Q(<RECIPIENT>
          <EMAIL>test@test.com'</EMAIL>
          <BODY_TYPE>HTML</BODY_TYPE>
        </RECIPIENT>)
      end



      let(:url) { "https://transact#{ENV['ENGAGE_INSTANCE']}.silverpop.com/XTMail" }

      let(:request) do
        "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>\n"+
          "<XTMAILING>\n"+
          "<CAMPAIGN_ID></CAMPAIGN_ID>\n"+
          "<SHOW_ALL_SEND_DETAIL>true</SHOW_ALL_SEND_DETAIL>\n"+
          "<SEND_AS_BATCH>false</SEND_AS_BATCH>\n"+
          "<NO_RETRY_ON_FAILURE>false</NO_RETRY_ON_FAILURE>\n"+
        "</XTMAILING>"
      end

      let(:response) do
        %Q(<?xml version="1.0" encoding="UTF-8" standalone="yes" ?>
           <XTMAILING_RESPONSE>
            <CAMPAIGN_ID>3556005</CAMPAIGN_ID>
            <TRANSACTION_ID>optional</TRANSACTION_ID>
            <RECIPIENTS_RECEIVED>1</RECIPIENTS_RECEIVED>
            <EMAILS_SENT>1</EMAILS_SENT>
            <NUMBER_ERRORS>0</NUMBER_ERRORS>
            <STATUS>0</STATUS>
            <ERROR_CODE>0</ERROR_CODE>
            <ERROR_STRING />
            <RECIPIENT_DETAIL>
              <EMAIL>sgade_sp@yahoo.com</EMAIL>
              <SEND_STATUS>0</SEND_STATUS>
              <ERROR_CODE>0</ERROR_CODE>
              <ERROR_STRING />
            </RECIPIENT_DETAIL>
          </XTMAILING_RESPONSE>)
      end

      it "send xml request" do
        stub_request(:post, url).with(:body => request,
                :headers => {'Accept'=>'*/*', 'Content-Type'=>'text/xml'}).
           to_return(:status => 200, :body => response, :headers => {})
        transact.query
        transact.should be_success
      end

      describe "#add_recipient" do

        it "returns right xml for two recipient" do
          xml = Nokogiri.XML transact.add_recipient(recipient).to_s
          xml.search('//RECIPIENT/EMAIL').first.content.should == "test@test.com"
          xml.search('//RECIPIENT/BODY_TYPE').first.content.should == "HTML"
        end

        it "returns right xml" do
          xml = Nokogiri.XML transact.add_recipient(recipient).to_s
          xml.search('//RECIPIENT/EMAIL').first.content.should == "test@test.com"
          xml.search('//RECIPIENT/BODY_TYPE').first.content.should == "HTML"
        end

        it "has personalizations" do
          xml = Nokogiri.XML transact.add_recipient(recipient).to_s
          xml.search('//RECIPIENT/PERSONALIZATION').should_not be_empty
        end

        it "hasn't personalizations" do
          xml = Nokogiri.XML transact.add_recipient(recipient.merge :personalizations => []).to_s
          xml.search('//RECIPIENT/PERSONALIZATION').should be_empty
        end

        it "returns nil if recipient is blank" do
          transact.add_recipient(nil).should be_nil
        end
      end

      describe "#add_personalizations" do

        let(:xml) do
          Nokogiri.XML transact.add_personalizations(recipient_xml, recipient[:personalizations])
        end

        it "returns not nil xml" do
          xml.search('//RECIPIENT/PERSONALIZATION').should_not be_nil
        end

        it "returns right xml" do
          tag_name =  xml.search('//RECIPIENT/PERSONALIZATION/TAG_NAME')
          value = xml.search('//RECIPIENT/PERSONALIZATION/VALUE')
          tag_name.first.content.should == "FIRST_NAME"
          value.first.content.should == "Joe"
          tag_name.last.content.should == "LAST_NAME"
          value.last.content.should == "Schmoe"
        end
      end

      describe "add_recipients" do
        it "has right recipients amount" do
          xml = Nokogiri.XML transact.add_recipients(recipients).to_s
          xml.search('//RECIPIENT').size.should == 3
        end

        it "returns right xml" do
          xml = Nokogiri.XML transact.add_recipients(recipients).to_s
          xml.search('//RECIPIENT/EMAIL').first.content.should == "test@test.com"
          xml.search('//RECIPIENT/BODY_TYPE').first.content.should == "HTML"
          xml.search('//RECIPIENT/EMAIL').last.content.should == "test3@test.com"
          xml.search('//RECIPIENT/BODY_TYPE').last.content.should == "HTML"
        end

        it "has personalizations" do
          xml = Nokogiri.XML transact.add_recipients([recipient]).to_s
          xml.search('//RECIPIENT/PERSONALIZATION').should_not be_empty
        end

        it "hasn't personalizations" do
          recip = recipient.merge :personalizations => []
          xml = Nokogiri.XML transact.add_recipients([recip]).to_s
          xml.search('//RECIPIENT/PERSONALIZATION').should be_empty
        end

        it "returns nil if recipient is blank" do
          transact.add_recipients(nil).should be_nil
        end
      end
    end

    describe "Remote tests", :remote => true do

    #   before(:all) do
    #     WebMock.allow_net_connect!
    #     Silverpop.configure do |config|
    #       config.setup_urls ENV['ENGAGE_INSTANCE'].nil? ? 5: ENV['ENGAGE_INSTANCE']
    #       config.engage_username = ENV['ENGAGE_USERNAME'].nil? ?
    #         "devonlyuser@billfloat.com" : ENV['ENGAGE_USERNAME']
    #       config.engage_password = ENV['ENGAGE_PASSWORD'].nil? ?
    #         "3s$-n9;Ux" : ENV['ENGAGE_PASSWORD']
    #       config.engage_ftp_username = ENV['ENGAGE_FTP_USERNAME'].nil? ?
    #         "devonlyuser@billfloat.com" : ENV['ENGAGE_FTP_USERNAME']
    #       config.engage_ftp_password = ENV['ENGAGE_FTP_PASSWORD'].nil? ?
    #         "3s$-n9;Ux" : ENV['ENGAGE_FTP_PASSWORD']
    #     end
    #     @campaign_id = ENV['CAMPAIGN_ID'].nil? ?
    #         123456 : ENV['CAMPAIGN_ID']
    #   end

    #   it "create compaign" do
    #     puts %Q(
    #       ***************************************************************
    #                               ATTENTION !!!
    #        You should input correct credentials for access to Silverpop!
    #       ***************************************************************
    #       ).color(:blue).background(:yellow)
    #     transact = Silverpop::Transact.new @campaign_id, recipients
    #     transact.query
    #     transact.should be_success
    #   end
    end
  end
end