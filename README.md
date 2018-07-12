# ActiveRecord::Filterable
![Build Status](https://travis-ci.org/nosolosoftware/active_record_filterable.svg?branch=master)

Let you add scopes to active_record document for filters.

## Installation

Add this line to your application's Gemfile:

    gem 'active_record_filterable'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install active_record_filterable

## Usage

#### Model

```ruby
class City < ActiveRecord::Base
  include ActiveRecord::Filterable

  field :name
  field :people

  filter_by(:name)
  filter_by(:people, ->(value) { where(:people.gt => value) })
  filter_by(:people_range, (lambda do |range_start, range_end|
    where(:people.lte => range_end,
          :people.gte => range_start)
  end))
end

City.create(name: 'city1', people: 100)
City.create(name: 'city2', people: 1000)
City.filter({name: 'city'}).count # => 2
City.filter({name: 'city1'}).count # => 1
City.filter({name: ''}).count # => 0
City.filter({people: 500}) # => 1
```

#### Operator

You can specify selector operator:

* and (default operator)
* or

```ruby
City.filter({name: 'city1', people: 1000}, 'and').count # => 0
City.filter({name: 'city1', people: 1000}, 'or').count # => 1
```

#### Range

Searches with more than one param is also available:

```ruby
City.filter(people_range: [500, 1000]).count # => 1
```

#### Rails controller

```ruby
class CitiesController
  def index
    respond_with City.filter(filter_params)
  end

  private

  def filter_params
    params.slice(:name, :people)
  end
end
```

#### Normalized values

Searches without considering accents are also supported. 

```ruby
  filter_by_normalized :name
```
enables to do sth like:

  ```ruby
  City.filter(name_normalized: 'text with accents')
  ```

It also depends on which adapter you are using.

* Postgresql: It makes use of [`unaccent`](https://www.postgresql.org/docs/9.1/static/unaccent.html). You need to activate in [your project](https://binarapps.com/blog/accent-insensitive-queries-in-rails-with-postgresql).
* Mysql, SqlServer: you only need to select an [accent-insensitive collation](https://binarapps.com/blog/accent-insensitive-queries-in-rails-with-postgresql). In cases where this is not possible you could even write:
    ```ruby
    filter_by :name, (lambda do |value|
      where("name LIKE ? COLLATE utf8_general_ci", "%#{value}%")
    end)
    ```

## Contributing

1. Fork it ( http://github.com/<my-github-username>/active_record_filterable/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
