# How to build this gem

NOTE: DON'T PUSH TO RUBYGEMS!

```
# Verify dependencies
bundle check

# Run specs
rake

# Commit, Push and Increase version number.
git push origin master

# Create a new version
gem build silverpop.gemspec
```

For example:

```
→ gem build silverpop.gemspec
  Successfully built RubyGem
  Name: silverpop
  Version: 1.2.1
  File: silverpop-1.2.1.gem
```
