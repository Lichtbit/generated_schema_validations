# GeneratedSchemaValidations

This Gem helps to transfer the defaults from the database schema to the rails validations. To do this, it uses the information in schema.rb and transfers it to a concern file. This file should be included in the version control.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'generated_schema_validations'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install generated_schema_validations


### Generate concern file

To generate `app/models/concerns/schema_validations.rb`:

    $ rails db:migrate

### Use validations

Add to `app/models/application_record.rb`:

```ruby
class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
  include SchemaValidations # to include auto generated validations
end
```

Use it in a model **after** you defined the associations:

```ruby
class User < ApplicationRecord
  belongs_to :client
  belongs_to :other

  validate :email_address, email_format: true

  schema_validations # to use auto generated validations

  def stuff; end
end
```

### Exclude from rubocop and simplecov

Add to simplecov config file (e.g. `.simplecov`):

```
  add_filter '/app/models/concerns/schema_validations.rb'
```

Add to rubocop config file (e. g. `config/rubocop.rb`):

```
AllCops:
  Exclude:
  - app/models/concerns/schema_validations.rb
```


## Usage

Every time you change schema.rb file with rake tasks `db:schema:dump` the generated file `schema_validations.rb` will fresh created. The task `db:migrate` use intern `db:schema:dump`.

It is hardcoded, that this will only run on development environment.


## How it works

```ruby
t.text :stuff, null: false
# results in
validate :stuff, presence: true

t.string :stuff, limit: 10
# results in
validate :stuff, length: { maximum: 10 }

t.integer :stuff
# results in
validate :stuff, numericality: true
```

You can watch changes on `schema_validations.rb` to understand the generated validations.

## Changelog

### 0.2.2

* Enable rails 7.0 usage

### 0.2.1

* Close tempfile before reading

### 0.2.0

* Add validations of date and datetime columns to be in database range

### 0.1.2

* Exclude columns in unique validations

### 0.1.1

* Add column type `binary`

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/Lichtbit/generated_schema_validations.


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
