require 'spec_helper'
require 'fakeweb'
require 'support/ftp/server'

module Silverpop
  describe Engage do

    before(:all) do
      FtpServer.start

      Engage::RAILS_DEFAULT_LOGGER = Logger.new(STDOUT, 'weekly')
      Engage::SILVERPOP_ENGAGE_USERNAME = "developmentapi@billfloat.com"
      Engage::SILVERPOP_ENGAGE_PASSWORD = "b!llFl0at"
      Engage::SILVERPOP_ENGAGE_FTP_USERNAME = "developmentapi@billfloat.com"
      Engage::SILVERPOP_ENGAGE_FTP_PASSWORD = "B1llFl0at"

      Engage::FTP_POST_URL = 'localhost'
      Engage::FTP_PORT     = FtpServer::PORT
    end

    after(:all) do
      FtpServer.stop
    end

    let(:request) do 
      '<Envelope><Body><ExportList>'+
        ('<LIST_ID>%d</LIST_ID>' % @id)+
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

    before(:each) do
      @engage = Engage.new
      @list_id = 713947
      @fields = %w[
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
        TOTAL_OUTSTANDING_LOANS
      ]
      FakeWeb.register_uri(:post, Engage::API_POST_URL, :body => response)
    end

    it "send xml request" do      
      Net::FTP.stub(:new).and_return(double('ftp').as_null_object)

      @engage.export_list(@list_id, @fields, "").should be_success
    end

    it "return csv file" do
      destination_file = File.expand_path('./support/ftp/temp.csv', File.dirname(__FILE__))
      etalon_file = File.expand_path('./support/ftp/folder/download/file.csv', File.dirname(__FILE__))

      @engage.export_list(@list_id, @fields, destination_file)

      destination_file.should be_same_file_as(etalon_file)
    end
  end
end
