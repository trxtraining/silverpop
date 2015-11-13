require 'spec_helper'
require 'support/ftp/server'
require 'webmock/rspec'

module Silverpop

  describe Engage do

    let(:fields) do
      %w[
        BILLPAY_APPROVED
        BILLPAY_COMPLETED
        BILLPAY_PROFILE_COMPLETED
        BILLPAY_REGISTRATION
        BILLPAY_SUBMITTED
        BILL_DUE_DATE
        BILL_DUE_DATE_4_RECURRING
        BILL_DUE_DATE_RECURRING
        CYCLE_INITIATION
        DROPOFF
        EMAIL
        EXTERNAL_ID
        FIRST_NAME
        FUNDS_AVAILABLE
        LAST_BILLER_ECOMMERCE
        LAST_BILLER_NAME
        LAST_DECLINED
        LAST_LOAN_APPLICATION_DATE
        LAST_LOGIN
        LOAN_CURRENTLY_OUTSTANDING
        LOAN_DUE_DATE
        LOAN_WRITTEN_OFF
        MID_WAY_DATE
        NUM_DAYS_OVERDUE
        NUM_LOANS_REPAID
        OPTOUT_COMING_DUE_EMAIL
        OPTOUT_COMING_DUE_SMS
        OPTOUT_DROPOFFS_EMAIL
        OPTOUT_DROPOFFS_SMS
        OPTOUT_NEWSLETTER_EMAIL
        OPTOUT_NEWSLETTER_SMS
        OPTOUT_NOTICES_SMS
        PAYMENT_POWER
        PREMIUM_ENROLLMENT_DATE
        REPAYMENT_DATE
        SOURCE
        STATE
        SUSPENDED
        TOTAL_OUTSTANDING_LOANS ]
    end

    let(:running_status) do
      "<Envelope><Body><RESULT>"+
        "<SUCCESS>TRUE</SUCCESS>"+
        "<JOB_ID>789052</JOB_ID>"+
        "<JOB_STATUS>RUNNING</JOB_STATUS>"+            
      "</RESULT></Body></Envelope>"
    end

    let(:waiting_status) do
      "<Envelope><Body><RESULT>"+
        "<SUCCESS>TRUE</SUCCESS>"+
        "<JOB_ID>789052</JOB_ID>"+
        "<JOB_STATUS>WAITING</JOB_STATUS>"+            
      "</RESULT></Body></Envelope>"
    end

    let(:complete_status) do
      "<Envelope><Body><RESULT>"+
        "<SUCCESS>TRUE</SUCCESS>"+
        "<JOB_ID>789052</JOB_ID>"+
        "<JOB_STATUS>COMPLETE</JOB_STATUS>"+            
      "</RESULT></Body></Envelope>"
    end

    describe "Local tests" do

      before(:all) do
        FtpServer.start

        Silverpop.configure do |config|
          config.setup_urls(ENV['ENGAGE_INSTANCE'])
          config.engage_username = ENV['ENGAGE_USERNAME']
          config.engage_password = ENV['ENGAGE_PASSWORD']
          config.engage_ftp_username = ENV['ENGAGE_FTP_USERNAME']
          config.engage_ftp_password = ENV['ENGAGE_FTP_PASSWORD']
        end

        Engage.instance_variable_set(:@ftp_url, "localhost")
        Engage.instance_variable_set(:@ftp_port, FtpServer::PORT)
      end

      after(:all) do
        FtpServer.stop
      end

      let(:url) { "https://api#{ENV['ENGAGE_INSTANCE']}.silverpop.com/XMLAPI" }
      let(:list_id) { 713947 }

      let(:request) do 
        '<Envelope><Body><ExportList>'+
          ('<LIST_ID>%d</LIST_ID>' % list_id)+
          '<EXPORT_TYPE>ALL</EXPORT_TYPE>'+
          '<EXPORT_FORMAT>CSV</EXPORT_FORMAT>'+
          '<ADD_TO_STORED_FILES />'+
          '<DATE_START>07/25/2011 12:12:11</DATE_START>'+
          '<DATE_END>09/30/2011 14:14:11</DATE_END>'+
          '<EXPORT_COLUMNS>'+
            '<COLUMN>FIRST_NAME</COLUMN>'+
            '<COLUMN>INITIAL</COLUMN>'+
            '<COLUMN>LAST_NAME</COLUMN>'+
          '</EXPORT_COLUMNS>'+
        '</ExportList></Body></Envelope>'
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

      it "sends xml request" do
        stub_request(:post, url).with(:body => request, 
          :headers => {'Content-type' => 'text/xml'}).to_return(:body => response)

        @engage = Engage.new

        @engage.query(request)
      end

      describe "export_list" do
        let(:export_list_request) do
          "<Envelope><Body><ExportList><LIST_ID>#{list_id}</LIST_ID><EXPORT_TYPE>ALL</EXPORT_TYPE><EXPORT_FORMAT>CSV</EXPORT_FORMAT><ADD_TO_STORED_FILES/><EXPORT_COLUMNS><COLUMN>BILLPAY_APPROVED</COLUMN><COLUMN>BILLPAY_COMPLETED</COLUMN><COLUMN>BILLPAY_PROFILE_COMPLETED</COLUMN><COLUMN>BILLPAY_REGISTRATION</COLUMN><COLUMN>BILLPAY_SUBMITTED</COLUMN><COLUMN>BILL_DUE_DATE</COLUMN><COLUMN>BILL_DUE_DATE_4_RECURRING</COLUMN><COLUMN>BILL_DUE_DATE_RECURRING</COLUMN><COLUMN>CYCLE_INITIATION</COLUMN><COLUMN>DROPOFF</COLUMN><COLUMN>EMAIL</COLUMN><COLUMN>EXTERNAL_ID</COLUMN><COLUMN>FIRST_NAME</COLUMN><COLUMN>FUNDS_AVAILABLE</COLUMN><COLUMN>LAST_BILLER_ECOMMERCE</COLUMN><COLUMN>LAST_BILLER_NAME</COLUMN><COLUMN>LAST_DECLINED</COLUMN><COLUMN>LAST_LOAN_APPLICATION_DATE</COLUMN><COLUMN>LAST_LOGIN</COLUMN><COLUMN>LOAN_CURRENTLY_OUTSTANDING</COLUMN><COLUMN>LOAN_DUE_DATE</COLUMN><COLUMN>LOAN_WRITTEN_OFF</COLUMN><COLUMN>MID_WAY_DATE</COLUMN><COLUMN>NUM_DAYS_OVERDUE</COLUMN><COLUMN>NUM_LOANS_REPAID</COLUMN><COLUMN>OPTOUT_COMING_DUE_EMAIL</COLUMN><COLUMN>OPTOUT_COMING_DUE_SMS</COLUMN><COLUMN>OPTOUT_DROPOFFS_EMAIL</COLUMN><COLUMN>OPTOUT_DROPOFFS_SMS</COLUMN><COLUMN>OPTOUT_NEWSLETTER_EMAIL</COLUMN><COLUMN>OPTOUT_NEWSLETTER_SMS</COLUMN><COLUMN>OPTOUT_NOTICES_SMS</COLUMN><COLUMN>PAYMENT_POWER</COLUMN><COLUMN>PREMIUM_ENROLLMENT_DATE</COLUMN><COLUMN>REPAYMENT_DATE</COLUMN><COLUMN>SOURCE</COLUMN><COLUMN>STATE</COLUMN><COLUMN>SUSPENDED</COLUMN><COLUMN>TOTAL_OUTSTANDING_LOANS</COLUMN></EXPORT_COLUMNS></ExportList></Body></Envelope>"
        end

        let(:destination_file) do
          File.expand_path('./support/ftp/temp.csv', File.dirname(__FILE__))
        end

        before(:each) do
          @engage = Engage.new
          stub_request(:post, url).
            to_return(:body => response).
            to_return(:body => waiting_status).
            to_return(:body => running_status).
            to_return(:body => complete_status)
        end

        it "send xml request" do
          Net::FTP.stub(:new).and_return(double('ftp').as_null_object)

          @engage.export_list(list_id, fields, destination_file).should be_success
        end

        it "return csv file" do
          # etalon_file = File.expand_path('./support/ftp/folder/download/file.csv', 
          #   File.dirname(__FILE__))
          # @engage.export_list(list_id, fields, destination_file)
          # 
          # destination_file.should be_same_file_as(etalon_file)
        end
      end

      describe "raw_recipient_data_export" do
        let(:request) do
          "<Envelope><Body><RawRecipientDataExport>"+
            "<COLUMNS>"+
              "<COLUMN><NAME>CustomerID</NAME></COLUMN>"+
              "<COLUMN><NAME>Address</NAME></COLUMN>"+
            "</COLUMNS>"+
            "<EVENT_DATE_START>12/01/2011 00:00:00</EVENT_DATE_START>"+
            "<EVENT_DATE_END>12/02/2011 23:59:00</EVENT_DATE_END>"+
            "<MOVE_TO_FTP/>"+
            "<EXPORT_FORMAT>0</EXPORT_FORMAT>"+
            "<EMAIL>admin@yourorg.com</EMAIL>"+
            "<ALL_EVENT_TYPES/>"+
            "<INCLUDE_INBOX_MONITORING/>"+
          "</RawRecipientDataExport></Body></Envelope>"
        end

        let(:response) do
          "<Envelope><Body><RESULT>"+
            "<SUCCESS>TRUE</SUCCESS>"+
            "<MAILING>"+
              "<JOB_ID>72649</JOB_ID>"+
              "<FILE_PATH>/download/file.csv</FILE_PATH>"+
            "</MAILING>"+
          "</RESULT></Body></Envelope>"
        end

        let(:destination_file) do
          File.expand_path('./support/ftp/temp.csv', File.dirname(__FILE__))
        end

        before(:each) do
          @engage = Engage.new          
          @options = Engage::RawRecipientDataOptions.new.tap do |opt|
            opt.event_date_start = "12/01/2011 00:00:00"
            opt.event_date_end   = "12/02/2011 23:59:00"
            opt.move_to_ftp      = true
            opt.export_format    = "0"
            opt.email            = "admin@yourorg.com"
            opt.all_event_types  = true
            opt.include_inbox_monitoring = true
            opt.columns << "CustomerID"
            opt.columns << "Address"
          end
          stub_request(:post, url).
            to_return(:body => response).
            to_return(:body => waiting_status).
            to_return(:body => running_status).
            to_return(:body => complete_status)
        end

        it "sends xml request" do
          Net::FTP.stub(:new).and_return(double('ftp').as_null_object)

          @engage.raw_recipient_data_export(@options, destination_file).should be_success
        end

        it "returns csv file" do
          # etalon_file = File.expand_path('./support/ftp/folder/download/file.csv', 
          #   File.dirname(__FILE__))
          # 
          # @engage.raw_recipient_data_export(@options, destination_file).should be_success
          # 
          # destination_file.should be_same_file_as(etalon_file)
        end
      end


      describe "#send_mailing" do

        let(:engage){Engage.new}
        let(:url) { "https://api#{ENV['ENGAGE_INSTANCE']}.silverpop.com/XMLAPI" }
        let(:response) do
          %Q{<Envelope>
  <Body>
   <RESULT>
     <SUCCESS>TRUE</SUCCESS>
     <MAILING_ID>9700</MAILING_ID>
   </RESULT>
   </Body>
</Envelope>
  }
        end
        before :each do
          Silverpop.configure do |config|
            config.setup_urls(ENV['ENGAGE_INSTANCE'])
          end
          Silverpop::Engage.configure do |config|
            config.mailing_base_name = 'Testing Automated emails'
            config.mailing_senders_name = 'Test Testerson'
            config.mailing_from_email = 'test.testerson@example.com'
            config.mailing_reply_to = 'test.testerson@example.com'
            config.mailing_parent_folder_path = 'Sent_Tests/Automated_Tests'
            config.mailing_visibility = '1'
          end

          stub_request(:post, url).with(:headers => {'Content-type' => 'text/xml'}).to_return(:body => response)
          engage.send_mailing({'TEMPLATE_ID' => '11945780',
                               'LIST_ID' => '5988165',
                               'SUBJECT' => 'This is a test email, please ignore.'},
                              {'SUB1'=>'VAL1', 'SUB2' => 'VAL2', 'SUB3'=>'VAL3'},
                              ['5988585'])
        end

      #  it "converts a hash to xml" do
      #    expect(engage.send(:to_xml, {"Test" => {'SUBS'=>["sub1","sub2"]}})).to eq "<Envelope><Test><SUBS><SUB><sub1></SUB><SUB>sub2</SUB></SUBS></Test></Envelope>"
      #  end

        it 'sends a mailing' do
          expect(engage.success?).to be true
        end

        it 'posts to silverpop' do
          expect(a_request(:post, url).
                     with(:body => /<TEMPLATE_ID>11945780<\/TEMPLATE_ID>\s*<LIST_ID>5988165<\/LIST_ID>\s*<SUBJECT>This is a test email, please ignore.<\/SUBJECT>/)).
              to have_been_made.once
        end

        it 'generates a unique name for the mailing' do
          expect(a_request(:post, url).
                     with(:body => /<MAILING_NAME>Testing Automated emails-\d*<\/MAILING_NAME>/)).
              to have_been_made.once
        end

        it "has response_xml" do
          expect(engage.response_xml).to match /<MAILING_ID>9700<\/MAILING_ID>/
        end

        it "has a result hash" do
          expect(engage.result['MAILING_ID']).to eq '9700'
        end

      end
    end


    describe "Remote tests", :remote => true do

      before(:all) do
        WebMock.allow_net_connect!

        Silverpop.configure do |config|
          config.setup_urls(ENV['ENGAGE_INSTANCE'])
          config.engage_username = "developmentapi@billfloat.com"
          config.engage_password = "b!llFl0at"
          config.engage_ftp_username = "developmentapi@billfloat.com"
          config.engage_ftp_password = "B1llFl0at"
        end
      end

      describe "raw_recipient_data_export" do

        let(:destination_file) do
          File.expand_path('./support/rrde_temp.zip', File.dirname(__FILE__))
        end

        it "returns zip file" do
          # @engage = Engage.new.tap { |e| e.login }
          # 
          # @options = Engage::RawRecipientDataOptions.new.tap do |opt|
          #   opt.event_date_start = "10/06/2013 00:00:00"
          #   opt.event_date_end   = "12/06/2013 23:59:00"
          #   opt.move_to_ftp      = true
          #   opt.export_format    = "0"
          #   opt.email            = "megas@ukr.net"
          #   opt.all_event_types  = true
          #   opt.include_inbox_monitoring = true
          #   opt.columns << "CustomerID"
          #   opt.columns << "Address"
          # end
          # 
          # @engage.raw_recipient_data_export(@options, destination_file).should be_success
          # 
          # destination_file.size.should == 53
        end
      end
    end
  end
end
