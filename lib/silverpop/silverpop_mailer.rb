class SilverpopMailer
  # sends to one recipient at a time for now
  attr_accessor :subject, :recipient, :campaign_id, :personalizations
  @@before_deliver_methods = []
  @@after_deliver_methods = []
  # some braindead callbacks. before_deliver methods will halt and not send if any callback returns false.
  # after_deliver methods just run and don't care what happens.
  def self.before_deliver(*methods)
    @@before_deliver_methods = methods
  end
  def self.after_deliver(*methods)
    @@after_deliver_methods = methods
  end
  def before_deliver_callbacks
    puts "before deliver callbacks are #{@@before_deliver_methods}"
    @@before_deliver_methods.each do |method|
      result = self.send(method)
      if result == false
        return false
      end
    end
    return true
  end
  def after_deliver_callbacks
    @@after_deliver_methods.each do |method|
      self.send(method)
    end
    return true
  end
  def deliver!
    puts "inside deliver!"
    return false unless before_deliver_callbacks
    puts "passed before callbacks!"
    @mail.query
    puts "@mail is #{@mail.inspect}"
    #TODO check return status and raise error here if allowed (configurable)
    puts "running after callbacks!"
    after_deliver_callbacks
    puts "finished after callbacks!"
    return true #TODO return false if email did not send
  end
  def initialize(method, *args)
    puts "about to send #{method} #{args} to #{self.inspect}"
    self.send(method, *args)
    puts "campaign_id is #{@campaign_id}"
    puts "email is #{@recipient}"
    @mail = Silverpop::Transact.new(campaign_id, [{:email => recipient, :personalizations => flat_hash_to_personalizations(personalizations)}])
    self
  end

  def self.method_missing(name, *args)
    if name.to_s.match(/^deliver_/)
      creator = name.to_s.sub("deliver_", "")
      # puts "creating method self.#{name}"
      # class_eval %{
      #   def self.#{name}
      #     puts "creating! new.create(:#{creator}, #{args})"
      #     mailer = new.create(:#{creator.to_sym}, *args)
      #     puts "delivering!"
      #     mailer.deliver!
      #   end
      # }, __FILE__, __LINE__
      # puts "calling method #{name}"
      # send(name)
      puts "creating! new.create(:#{creator}, #{args})"
      mailer = new(creator.to_sym, *args)
      puts "mailer is #{mailer.inspect}"
      puts "delivering!"
      mailer.deliver!
    else
      super
    end
  end
  def respond_to?(name)
    if name.to_s.match(/^deliver/)
      true
    else
      super
    end
  end

  protected
    def flat_hash_to_personalizations(hash)
      #personalizations = [{:tag_name => "BILL_FLOAT_TEST_BODY", :value => "<![CDATA[This is the <b>body</b> of the email.]]>"}]
      personalizations = []
      hash.each_pair do |k,v|
        personalizations << {:tag_name => k.to_s, :value => v}
      end
      personalizations
    end
end