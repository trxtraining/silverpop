module Silverpop

  class Transact < Silverpop::Base

    attr_accessor :response_doc, :query_doc, :xml
    protected :response_doc, :query_doc, :xml

    class << self
      attr_accessor :url, :ftp_url, :username, :password
    end

    def initialize(campaign_id, recipients=[], options={})
      query_doc, response_doc = nil, nil
      xml_template(campaign_id, recipients, options)
    end

    def query_xml
      return '' if query_doc.nil?
      query_doc.to_s
    end

    def response_xml
      return '' if response_doc.nil?
      response_doc.to_s
    end

    def query
      self.response_doc = Hpricot::XML( super(query_doc.to_s) )
      log_error unless success?
    end

    def submit_batch(batch_file_path)
      Net::FTP.open(ftp_url, username, password) do |ftp|
        ftp.passive = true  # IMPORTANT! SILVERPOP NEEDS THIS OR IT ACTS WEIRD.
        ftp.chdir('transact')
        ftp.chdir('inbound')
        ftp.puttextfile(batch_file_path)
        ftp.close
      end
    end

    def save_xml(file_path)
      File.open(file_path, 'w') do |f|
        f.puts query_xml
        f.close
      end
      file_path
    end

    def success?
      response_doc.at('STATUS').innerHTML.to_i == 0
    end

    def error_message
      return 'Query has not been executed.' if response_doc.blank?
      return false if success?
      response_doc.at('ERROR_STRING').innerHTML
    end

    def add_recipient(recipient)
      return if recipient.blank?
      (query_doc/:XTMAILING).append build_recipient(recipient)
    end

    def add_recipients(recipients)
      return if recipients.blank?
      recipients_xml = ''
      recipients.each do |recipient|
        recipients_xml += build_recipient(recipient)
      end
      (query_doc/:XTMAILING).append recipients_xml
    end

    def add_personalizations(recipient_xml, personalizations)
      r_doc = Hpricot::XML(recipient_xml)
      personalizations.each do |p|
        (r_doc/:RECIPIENT).append xml_recipient_personalization p
      end
      r_doc.to_s
    end

  protected

    def build_recipient(recipient)
      r_xml = xml_recipient recipient[:email]
      if recipient[:personalizations].size > 0
        r_xml = add_personalizations r_xml, recipient[:personalizations]
      end
      r_xml
    end

    def log_error
      if defined?(Rails)
        log :error, "Silverpop::Transact Error:   #{error_message}"
        log :warn, "@xml:\n#{xml.inspect}"
        log :info, "@query_doc:\n#{query_doc.inspect}"
      end
    end

    def log_warn(message)
      log(:warn, message) if defined?(Rails) && (not Rails.env.test?)
    end

    def xml_template(campaign_id, recipients=[], options={})
      options = { :transaction_id       => '',
            :show_all_send_detail => 'true',
            :send_as_batch        => 'false',
            :no_retry_on_failure  => 'false',
            :save_columns => []
          }.merge options
      self.xml = (
        "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>\n"+
        "<XTMAILING>\n"+
          "<CAMPAIGN_ID>%s</CAMPAIGN_ID>\n"+
          "<SHOW_ALL_SEND_DETAIL>%s</SHOW_ALL_SEND_DETAIL>\n"+
          "<SEND_AS_BATCH>%s</SEND_AS_BATCH>\n"+
          "<NO_RETRY_ON_FAILURE>%s</NO_RETRY_ON_FAILURE>\n"+
          "#{ save_columns(options[:save_columns]) }"+
        "</XTMAILING>"
      ) % [ campaign_id,
            options[:show_all_send_detail],
            options[:send_as_batch],
            options[:no_retry_on_failure] ]
      self.query_doc = Hpricot::XML(xml)
      unless options[:transaction_id].blank?
        (query_doc/:XTMAILING).append(
            '<TRANSACTION_ID>%s</TRANSACTION_ID>' % options[:transaction_id] )
      end

      log :warn, "add_recipients(#{recipients.inspect})"
      add_recipients recipients
    end

    def xml_recipient(email)
      log :warn, "xml_recipient(#{email.inspect})"

      ( "\n" + '<RECIPIENT>'+
          '<EMAIL>%s</EMAIL>'+
          '<BODY_TYPE>HTML</BODY_TYPE>'+
        '</RECIPIENT>' + "\n"
      ) % email
    end

    def xml_recipient_personalization(personalization)
      log :warn, "xml_recipient_personalization(#{personalization.inspect})"
      tag_name = personalization[:tag_name]
      value = personalization[:value]
      %Q(<PERSONALIZATION>
        <TAG_NAME>#{tag_name}</TAG_NAME>
        <VALUE>#{value}</VALUE>
      </PERSONALIZATION>)
    end

    def save_columns(fields)
      unless fields.empty?
        fields_xml = ""
        fields.each { |field| fields_xml << %Q(<COLUMN_NAME>%s</COLUMN_NAME>\n) % field }
        %Q(<SAVE_COLUMNS>\n%s</SAVE_COLUMNS>\n) % fields_xml
      end
    end
  end
end
