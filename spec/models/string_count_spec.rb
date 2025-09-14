# frozen_string_literal: true

require 'rails_helper'

RSpec.describe StringCount, type: :model do
  describe 'validations' do
    it 'creates a string count record successfully' do
      string_count = StringCount.new(unicode: 'A', count: 10)
      expect(string_count).to be_valid
    end
  end

  describe 'scopes' do
    let!(:string_count_a) { StringCount.create!(unicode: 'A', count: 10) }
    let!(:string_count_b) { StringCount.create!(unicode: 'B', count: 20) }
    let!(:string_count_a2) { StringCount.create!(unicode: 'A', count: 15) }

    describe '.by_unicode' do
      it 'returns records with specified unicode' do
        results = StringCount.by_unicode('A')

        expect(results.count).to eq(2)
        expect(results).to include(string_count_a, string_count_a2)
        expect(results).not_to include(string_count_b)
      end

      it 'returns empty relation for non-existent unicode' do
        results = StringCount.by_unicode('Z')
        expect(results).to be_empty
      end

      it 'handles case-sensitive unicode' do
        StringCount.create!(unicode: 'a', count: 5)

        uppercase_results = StringCount.by_unicode('A')
        lowercase_results = StringCount.by_unicode('a')

        expect(uppercase_results.count).to eq(2)
        expect(lowercase_results.count).to eq(1)
      end
    end
  end

  describe 'database attributes' do
    let(:string_count) { StringCount.create!(unicode: 'TEST', count: 100) }

    it 'persists unicode correctly' do
      expect(string_count.unicode).to eq('TEST')
    end

    it 'persists count correctly' do
      expect(string_count.count).to eq(100)
    end

    it 'has timestamps' do
      expect(string_count.created_at).to be_present
      expect(string_count.updated_at).to be_present
    end
  end

  describe 'edge cases' do
    it 'handles special unicode characters' do
      special_char = StringCount.create!(unicode: '🚀', count: 1)
      expect(special_char.unicode).to eq('🚀')
    end

    it 'handles zero count' do
      zero_count = StringCount.create!(unicode: 'Z', count: 0)
      expect(zero_count.count).to eq(0)
    end

    it 'handles large count values' do
      large_count = StringCount.create!(unicode: 'L', count: 999999)
      expect(large_count.count).to eq(999999)
    end
  end
end