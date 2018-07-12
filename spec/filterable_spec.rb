require 'spec_helper'

RSpec.describe ActiveRecord::Filterable do
  class City < ActiveRecord::Base
    include ActiveRecord::Filterable

    default_scope -> { where(active: true) }

    filter_by :code
    filter_by(:active)
    filter_by(:name)
    filter_by(:code)
    filter_by(:people, ->(value) { where(City.arel_table[:people].gt(value)) })
    filter_by(:people_in, ->(value) { where(people: value) })
    filter_by(:people_range, (lambda do |range_start, range_end|
      where(people: range_start..range_end)
    end))
    filter_by_normalized(:name)
  end

  before do
    City.unscoped.destroy_all
  end

  context 'when use default operator' do
    it 'should create correct selector' do
      expect(City.filter(code: :code1).to_sql).to eq(
        "SELECT \"cities\".* FROM \"cities\" WHERE \"cities\".\"active\" = 't' AND" \
        " \"cities\".\"code\" = 'code1'"
      )
    end

    it 'should filter by default filter' do
      City.create(code: :code1)
      City.create(code: :code2)
      expect(City.filter(code: :code1).count).to eq(1)
      expect(City.filter(code: :code1).first.code).to eq('code1')
    end

    it 'should filter by match filter' do
      City.create(name: 'city1')
      City.create(name: 'city2')

      expect(City.filter(name: 'city').count).to eq(0)
      expect(City.filter(name: 'city1').count).to eq(1)
      expect(City.filter(name: 'city1').first.name).to eq('city1')
    end

    it 'should filter by custom filter' do
      City.create(people: 100)
      City.create(people: 1000)
      expect(City.filter(people: 500).count).to eq(1)
      expect(City.filter(people: 500).first.people).to eq(1000)
    end

    it 'should filter by normalized filter' do
      City.create(name: 'spaIn')
      City.create(name: 'frAnce')
      expect(City.filter(name_normalized: 'spain').first.name).to eq('spaIn')
      expect(City.filter(name_normalized: 'france').first.name).to eq('frAnce')
    end

    it 'should respect previous selector' do
      City.create(name: 'city1', people: 100)
      City.create(name: 'city2', people: 1000)
      City.create(name: 'city3', people: 2000)
      expect(City.where(name: 'city2').filter(people: '500').count).to eq(1)
      expect(City.where(name: 'city2').filter(people: '500').first.name).to eq('city2')
    end
  end

  context 'when use and operator' do
    it 'should filter using and query' do
      City.create(name: 'city1', people: 100)
      City.create(name: 'city2', people: 2000)
      expect(City.filter({name: 'city1', people: '2000'}, 'and').count).to eq(0)
    end
  end

  context 'when use or operator' do
    it 'should create correct selector' do
      City.create(code: :code1)
      expect(City.filter({code: :code1, people: 2}, 'or').to_sql).to eq(
        "SELECT \"cities\".* FROM \"cities\" WHERE \"cities\".\"active\" = 't' AND" \
        " (\"cities\".\"code\" = 'code1' OR \"cities\".\"people\" > 2)"
      )
    end

    it 'should filter using or query' do
      City.create(name: 'city1', people: 100)
      City.create(name: 'city2', people: 2000)
      expect(City.filter({name: 'city1', people: '2000', active: false}, 'or').count).to eq(1)
    end
  end

  context 'when use invalid filter' do
    before do
      City.create(name: 'city1')
      City.create(name: 'city2')
      City.create(active: false)
    end

    it 'should respect default_scope' do
      expect(City.filter(invalid: 'val').count).to eq(2)
    end

    it 'should ignore filter' do
      expect(City.filter(invalid: 'val').count).to eq(2)
    end
  end

  context 'when filter params are nil' do
    before do
      City.create(name: 'city1')
      City.create(name: 'city2')
      City.create(active: false)
    end

    it 'should respect default_scope' do
      expect(City.filter(nil).count).to eq(2)
    end

    it 'should ignore filter' do
      expect(City.filter(nil).count).to eq(2)
    end
  end

  context 'when value is an array' do
    before do
      City.create(people: 100)
      City.create(people: 500)
      City.create(people: 500, active: false)
      City.create(people: 1000)
      City.create(people: 1000)
    end

    it 'filter should receive all the values' do
      expect(City.filter(people_range: [500, 1000]).count).to eq(3)
    end

    it 'does not break compatibility with filters receiving only one param as array' do
      expect(City.filter(people_in: [500, 100]).count).to eq(2)
    end
  end

  context 'when value is nil' do
    before do
      City.create(people: 100)
      City.create(people: 500)
    end

    it 'should apply filter' do
      expect(City.filter(people: nil).count).to eq(0)
    end
  end

  context 'when value is empty string' do
    before do
      City.create(people: 100)
      City.create(people: 500)
    end

    it 'should apply filter' do
      expect(City.filter(people: '').count).to eq(0)
    end
  end

  context 'when value is a Boolean' do
    it 'should filter using a query' do
      City.create(name: 'city1')
      City.create(name: 'city2', active: false)
      expect(City.unscoped.filter(active: false).count).to eq(1)
    end
  end

  context 'when filter is applied on a scope' do
    it 'previous scope is maintained' do
      City.create(name: '2', people: 100)
      City.create(name: '1', people: 500)
      City.create(name: '1', people: 1000)
      City.create(name: '1', people: 1000)
      expect(City.where(name: '2').filter(nil).count).to eq(1)
    end
  end
end
