Gem::Specification.new do |s|
  s.name     = "silverpop"
  s.version  = "1.1.0"
  s.date     = "2011-07-13"
  s.summary  = "Silverpop Engage and Transact API -- Extracted from ShoeDazzle.com, gemified by Billfloat"
  s.email    = "bill@billfloat.com"
  s.homepage = "http://github.com/billfloat/silverpop/tree/master"
  s.description = "Silverpop allows for seamless integration from Ruby with the Engage and Transact API."
  s.authors  = ["George Truong, Bill Abney"]

  s.has_rdoc = false
  s.rdoc_options = ["--main", "README"]
  s.extra_rdoc_files = ["README"]

  # run git ls-files to get an updated list
  s.files = %w[
    MIT-LICENSE
    README
    Rakefile
    init.rb
    install.rb
    lib/silverpop.rb
    lib/silverpop/base.rb
    lib/silverpop/engage.rb
    lib/silverpop/transact.rb
    tasks/silverpop_tasks.rake
    test/silverpop_test.rb
    uninstall.rb
  ]
  s.test_files = %w[
  ]
end
