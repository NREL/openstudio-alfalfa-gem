# Openstudio Metadata Gem

This gem produces semantic data representations for OpenStudio models

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'openstudio-metadata'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install 'openstudio-metadata'

## Note

This Gem requires OpenStudio@3.0 or greater 

## TODO

- [ ] Remove measures from OpenStudio-Measures to standardize on this location
- [ ] Update measures to code standards
- [ ] Review and fill out the gemspec file with author and gem description

# Releasing

* Update change log
* Update version in `/lib/openstudio/openstudio-metadata/version.rb`
* Merge down to master
* Release via github
* run `rake release` from master

# Developing
- Create branch
- Work on feature
- Add commits
- Run `bundle exec rake rubocop:auto_correct`
- Commit and push
- Add PR to feature 