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
    context 'when exact matching is used' do
      before do
        City.create(code: :code1)
        City.create(code: :code2)
      end

      it 'filters' do
        expect(City.filtrate(code: :code1).count).to eq(1)
        expect(City.filtrate(code: :code1).first.code).to eq('code1')
      end

      it 'doesn\'t find anything with partial match' do
        expect(City.filtrate(code: :code).count).to eq(0)
      end
    end

    context 'when filter is invalid' do
      before do
        City.create(code: :code1)
        City.create(code: :code2)
      end

      it 'ignore filter' do
        expect(City.filtrate(code: :code1, invalid: 'xxx').count).to eq(1)
        expect(City.filtrate(invalid: 'xxx').count).to eq(2)
      end
    end

    context 'when filter by nil' do
      before do
        City.create(name: 'city1')
        City.create(name: 'city2')
        City.create(active: false)
      end

      it 'respects default_scope' do
        expect(City.filtrate(nil).count).to eq(2)
      end

      it 'ignores filter' do
        expect(City.filtrate(nil).count).to eq(2)
      end
    end

    context 'with invalid filter' do
      before do
        City.create(name: 'city1')
        City.create(name: 'city2')
        City.create(active: false)
      end

      it 'should respect default_scope' do
        expect(City.filtrate(invalid: 'val').count).to eq(2)
      end

      it 'should ignore filter' do
        expect(City.filtrate(invalid: 'val').count).to eq(2)
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

      it 'receives all the values' do
        expect(City.filtrate(people_range: [500, 1000]).count).to eq(3)
      end

      it 'does not break compatibility with filters receiving only one param as array' do
        expect(City.filtrate(people_in: [500, 100]).count).to eq(2)
      end
    end

    context 'when value is empty string' do
      before do
        City.create(people: 100)
        City.create(people: 500)
      end

      it 'applies filter' do
        expect(City.filtrate(people: '').count).to eq(0)
      end
    end

    context 'when value is a Boolean' do
      before do
        City.create(name: 'city1')
        City.create(name: 'city2', active: false)
      end

      it 'filters using a query' do
        expect(City.unscoped.filtrate(active: false).count).to eq(1)
      end
    end

    context 'when exact matching is used' do
      before do
        City.create(people: 100)
        City.create(people: 1000)
      end

      it 'filters' do
        expect(City.filtrate(people: 500).count).to eq(1)
        expect(City.filtrate(people: 500).first.people).to eq(1000)
      end
    end

    context 'when normalize matching is used' do
      before do
        City.create(name: 'spaIn')
        City.create(name: 'frAnce')
        City.create(name: 'itály')
        City.create(name: '_russian%')
      end

      it 'filters ignoring upcase' do
        expect(City.filtrate(name_normalized: 'spain').first.name).to eq('spaIn')
        expect(City.filtrate(name_normalized: 'france').first.name).to eq('frAnce')
      end

      it 'filters ignoring special characters', sqlite: false do
        expect(City.filtrate(name_normalized: '%').first.name).to eq('_russian%')
      end

      it 'filters ignoring accents', sqlite: false do
        expect(City.filtrate(name_normalized: 'italy').first.name).to eq('itály')
      end
    end

    context 'when is applied in query' do
      before do
        City.create(name: '2', people: 100)
        City.create(name: '1', people: 500)
        City.create(name: '1', people: 1000)
        City.create(name: '1', people: 1000)
      end

      it 'is maintained' do
        expect(City.where(name: '2').filtrate(nil).count).to eq(1)
        expect(City.where(name: '2').filtrate(nil).first.name).to eq('2')
        expect(City.where(name: '1').filtrate(people: 900).count).to eq(2)
      end

      context 'when filter is invalid' do
        it 'ignore filter' do
          expect(City.where(name: '1').filtrate(invalid: 900).count).to eq(3)
        end
      end
    end
  end

  context 'when use "and" operator' do
    before do
      City.create(name: 'city1', people: 100)
      City.create(name: 'city2', people: 2000)
    end

    it 'filters' do
      expect(City.filtrate({name: 'city1', people: '2000'}, 'and').count).to eq(0)
    end
  end

  context 'when use "or" operator' do
    before do
      City.create(name: 'city1', people: 100)
      City.create(name: 'city2', people: 2000)
    end

    it 'filters' do
      expect(City.filtrate({name: 'city1', people: 500}, 'or').count).to eq(2)
    end
  end
end
