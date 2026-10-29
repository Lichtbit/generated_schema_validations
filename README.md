# GeneratedSchemaValidations

This Gem helps to transfer the defaults from the database schema to the rails validations. To do this, it uses the information in schema.rb and transfers it to a concern file. This file should be included in the version control.

## Requirements

* Ruby 3.2 or newer
* Rails 7.2 to 8.1
* `db/schema.rb` as schema format (`structure.sql` is not supported)

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

Use it in a model **after** you defined the associations and enums:

```ruby
class User < ApplicationRecord
  belongs_to :client
  belongs_to :other

  enum :actived, no: 0, yes: 1

  validates :email_address, email_format: true

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

### Compare online database after deployment with capistrano

```ruby
# Add to Capfile

require 'generated_schema_validations/capistrano_tasks'

```

## Usage

Every time you change schema.rb file with rake tasks `db:schema:dump` the generated file `schema_validations.rb` will fresh created. The task `db:migrate` use intern `db:schema:dump`.

It is hardcoded, that this will only run on development environment.


## How it works

```ruby
t.text :stuff, null: false
# results in
validates :stuff, presence: true

t.string :stuff, limit: 10
# results in
validates :stuff, length: { maximum: 10, allow_nil: true }

t.integer :stuff
# results in
validates :stuff, numericality: { only_integer: true, greater_than_or_equal_to: -2147483648, less_than: 2147483648, allow_nil: true }
```

You can watch changes on `schema_validations.rb` to understand the generated validations.

## Changelog

### 0.7.0

* requires Ruby 3.2 and Rails 7.2 or newer
* supports all PostgreSQL column types of Rails (e.g. `citext`, `money`, `bit`, `enum`, `hstore`, ranges and geometric types)
* `enum` columns are validated to contain a value of the PostgreSQL enum type
* `serial` and `bigserial` columns are not validated for presence, because the database sets them
* unique constraints are validated like unique indexes
* not null `json`, `jsonb`, `hstore` and array columns accept empty values (`{}` or `[]`)
* the generated file contains only the validator classes used by the tables
* `bigint` columns and `integer` columns with `limit` get a range validation
* the generated file is the same on all Ruby versions (`Hash#inspect` changed with Ruby 3.4)
* abstract classes do not need `schema_validations` anymore
* ignore `virtual` columns, check and exclusion constraints
* skip generating if the schema format is not ruby
* adds tests

### 0.6.1

* adds support for Rails 8.1 (integer range validations no longer use the private `ActiveRecord::Type::Integer#range`, which was removed in Rails 8.1)

### 0.6.0

* add a relaxed mode for model validations in migrations

```ruby
create_table :new_model do |t|
  t.timestamps null: false
end
SchemaValidations.relaxed!
NewModel.create!
```

### 0.5.5

* ignore geography fields

### 0.5.4

* adds support for time fields
* fix errors on overflowing column values

### 0.5.3

* adds support for Rails 7.2

### 0.5.2

* sort generated validates to ignore column order

### 0.5.1

* raise info about where-unique conditions only in local envs

### 0.5

* Enables automatic testing after deployment using Capistrano to compare the online database with the local one and automatically warn of any differences.

```ruby
# Add to Capfile

require 'generated_schema_validations/capistrano_tasks'

```

### 0.4

* JSON and JSONB fields can have an empty hash and still be considered present

### 0.3.1

* Add exclusion for enum fields

### 0.3.0

* Check usage of schema_validations (see #3)
* Force excluding unique validations with where clause (see #2)

### 0.2.3

* Add `jsonb` and `xml` as possible field type

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

## Development

The specs run with SQLite. Set `DATABASE_URL` to run the PostgreSQL specs too:

    $ DATABASE_URL=postgres://user:password@localhost/generated_schema_validations_test bundle exec rspec

Other Rails versions are tested with the gemfiles in `gemfiles/`:

    $ BUNDLE_GEMFILE=gemfiles/rails_7.2.gemfile bundle exec rspec

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/Lichtbit/generated_schema_validations.


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
