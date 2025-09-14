# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RankMaster, type: :model do
  describe 'creation and persistence' do
    it 'creates a rank master successfully' do
      rank = RankMaster.create!(name: 'Gold')

      expect(rank).to be_persisted
      expect(rank.name).to eq('Gold')
    end

    it 'has timestamps' do
      rank = RankMaster.create!(name: 'Silver')

      expect(rank.created_at).to be_present
      expect(rank.updated_at).to be_present
    end
  end

  describe 'validations and constraints' do
    it 'persists different rank names' do
      ranks = ['Bronze', 'Silver', 'Gold', 'Platinum', 'Diamond']

      ranks.each do |rank_name|
        rank = RankMaster.create!(name: rank_name)
        expect(rank.name).to eq(rank_name)
      end
    end

    it 'handles special characters in name' do
      special_rank = RankMaster.create!(name: 'VIP★')
      expect(special_rank.name).to eq('VIP★')
    end
  end

  describe 'database operations' do
    let!(:rank1) { RankMaster.create!(name: 'Beginner') }
    let!(:rank2) { RankMaster.create!(name: 'Expert') }

    it 'updates rank name' do
      rank1.update!(name: 'Advanced Beginner')
      expect(rank1.reload.name).to eq('Advanced Beginner')
    end

    it 'deletes rank successfully' do
      expect { rank1.destroy! }.to change(RankMaster, :count).by(-1)
    end

    it 'finds rank by name' do
      found_rank = RankMaster.find_by(name: 'Expert')
      expect(found_rank).to eq(rank2)
    end
  end

  describe 'associations' do
    let(:rank) { RankMaster.create!(name: 'Master') }

    it 'can be associated with result string counts' do
      result = ResultStringCount.create!(rank_master: rank)
      expect(result.rank_master).to eq(rank)
    end
  end
end