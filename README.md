Silverpop
=========

Silverpop Engage and Transact API -- Extracted from ShoeDazzle.com

Silverpop allows for seamless integration from Ruby with the Engage and Transact API. Built on Rails
2.1.0. Requires hpricot, net/http, net/ftp, and uri.

Configurations
==============

Silverpop.configure do |config|
  config.setup_urls(instance_number)
  config.engage_username = "mail@billfloat.com"
  config.engage_password = "password"
  config.engage_ftp_username = "mail@billfloat.com"
  config.engage_ftp_password = "password"
end

Testing
=======

```
ENGAGE_INSTANCE=5 ENGAGE_USERNAME='engage_username@billfloat.com' ENGAGE_PASSWORD='engage_password' ENGAGE_FTP_USERNAME='engage_ftp_username@billfloat.com' ENGAGE_FTP_PASSWORD='engage_ftp_password' INCLUDE_REMOTE=true rspec spec
```

Examples
========

ENGAGE


  Creating an import map file:

    map_file_path  = 'LIST_MAP.XML'

    list_info = { :action       => 'ADD_AND_UPDATE',
                  :list_id      => 1234567,
                  :file_type    => 0,
                  :has_headers  => true }

    columns   = [ { :name=>'EMAIL',         :type=>9, :is_required=>true,   :key_column=>true },
                  { :name=>'FIRST_NAME',    :type=>0, :is_required=>false,  :key_column=>false },
                  { :name=>'LAST_NAME',     :type=>0, :is_required=>false,  :key_column=>false } ]

    mappings  = [ { :index=>1,  :name=>'EMAIL' },
                  { :index=>2,  :name=>'FIRST_NAME' },
                  { :index=>3,  :name=>'LAST_NAME' } ]

    engage_api = Silverpop::Engage.new
    engage_api.create_map_file(map_file_path, list_info, columns, mappings)


  Creating the gzipped CSV data file:

    csv_file_path = 'LIST_DATA.csv.gz'
    users = User.all()
    Zlib::GzipWriter.open(csv_file_path) do |gz|
      gz.write [ 'EMAIL', 'FIRST_NAME', 'LAST_NAME' ].join(',') + "\n"
      users.each { |u| gz.write [ u.email, u.first_name, u.last_name ].join(',') + "\n" }
      gz.close
    end


  FTPing import map file and gzipped CSV file over to Silverpop:

    engage_api = Silverpop::Engage.new
    engage_api.login
    engage_api.import_list(map_file_path, csv_file_path)
    engage_api.logout


  Grab a list of all the queries in Silverpop and recalculate them. (This is really handy after you
  update your email list):

    api = Silverpop::Engage.new, []
    api.login

    doc = Hpricot::XML( api.get_lists(1, 1) ) # Public queries
    (doc/:LIST).each { |n| api.calculate_query(n.at('ID').innerHTML) }

    doc = Hpricot::XML( api.get_lists(0, 1) ) # Private queries
    (doc/:LIST).each { |n| api.calculate_query(n.at('ID').innerHTML) }

    api.logout

  Send out a mailing to a preconfigured list:
  
  ```Ruby
  
    #this sets up some reasonable defaults
    Silverpop::Engage.configure do |config|
      config.mailing_base_name = 'Testing Automated emails'
      config.mailing_senders_name = 'Test Testerson'
      config.mailing_from_email = 'test.testerson@example.com'
      config.mailing_reply_to = 'test.testerson@example.com'
      config.mailing_parent_folder_path = 'Sent_Tests/Automated_Tests'
      config.mailing_visibility = '1'
    end
    
    minimum_parameters = {'TEMPLATE_ID' => '11945780',
                          'LIST_ID' => '5988165',
                          'SUBJECT' => 'This is a test email, please ignore.'}
    hash_of_substitutions = {'SUB1'=>'VAL1', 'SUB2' => 'VAL2', 'SUB3'=>'VAL3'}
    array_of_suppression_lists = ['123123','345345']
    
    engage.send_mailing({minimum_parameters,hash_of_substitutions,array_of_suppression_lists)
          end
  ```
  
  Execute a designated command
  
  ```Ruby
    
    command = 'GetListMetaData'
    hash_of_params = {'LIST_ID' => '12345'}
     
    engage.post_request(command,hash_of_params)
    engage.result['NAME']  # => 'Test3'
    
  ```
  
  

  Other:

    Please look through the functions in lib/engage.rb


TRANSACT


  Defining recipients:

    recipient = { :email            => 'test@test.com',
                  :personalizations => [
                      {:tag_name => 'FIRST_NAME', :value => 'Joe'},
                      {:tag_name => 'LAST_NAME',  :value => 'Schmoe'}
                  ] }
    recipients = [  recipient,
                    { :email            => 'test2@test.com',
                    :personalizations => [
                        {:tag_name => 'FIRST_NAME', :value => 'John'},
                        {:tag_name => 'LAST_NAME',  :value => 'Smith'}
                    ] },
                    { :email            => 'test3@test.com',
                      :personalizations => [
                        {:tag_name => 'FIRST_NAME', :value => 'Jane'},
                        {:tag_name => 'LAST_NAME',  :value => 'Doe'}
                    ] } ]


  Transact HTTP Sample Usage:

    campaign_id = 1234567
    sp = Silverpop::Transact.new campaign_id, recipients
    sp.query

  Transact FTP Sample Usage:

    campaign_id = 1234567
    options.merge!( { :send_as_batch => 'true' } )

    transact = Silverpop::Transact.new(campaign_id, recipients, options)
    transact.save_xml     file_path
    transact.submit_batch file_path


Copyright (c) 2010 George Truong, released under the MIT license
