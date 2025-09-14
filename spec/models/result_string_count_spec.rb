# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ResultStringCount, type: :model do
  describe 'associations' do
    let(:result_string_count) { ResultStringCount.new }

    it 'belongs to rank_master (optional)' do
      association = described_class.reflect_on_association(:rank_master)

      expect(association.macro).to eq(:belongs_to)
      expect(association.options[:optional]).to be true
    end

    it 'belongs to result_comment_master (optional)' do
      association = described_class.reflect_on_association(:result_comment_master)

      expect(association.macro).to eq(:belongs_to)
      expect(association.options[:optional]).to be true
    end

    it 'belongs to result_detaile_master (optional)' do
      association = described_class.reflect_on_association(:result_detaile_master)

      expect(association.macro).to eq(:belongs_to)
      expect(association.options[:optional]).to be true
      expect(association.options[:foreign_key]).to eq('id')
    end
  end

  describe 'alias attributes' do
    let(:rank_master) { RankMaster.create!(name: 'Gold') }
    let(:comment_master) { ResultCommentMaster.create!(comment: 'Great job!') }
    let(:detaile_master) { ResultDetaileMaster.create!(detaile: 'Detailed info') }

    let(:result_string_count) do
      ResultStringCount.create!(
        rank_master: rank_master,
        result_comment_master: comment_master,
        result_detaile_master: detaile_master
      )
    end

    it 'aliases rank_master as rank' do
      expect(result_string_count.rank).to eq(rank_master)
    end

    it 'aliases result_comment_master as comment' do
      expect(result_string_count.comment).to eq(comment_master)
    end

    it 'aliases result_detaile_master as detaile' do
      expect(result_string_count.detaile).to eq(detaile_master)
    end
  end

  describe 'creation and persistence' do
    it 'creates successfully without associations' do
      result = ResultStringCount.create!(
        string_count: 42,
        accuracy_rate: 85.5
      )

      expect(result).to be_persisted
      expect(result.string_count).to eq(42)
      expect(result.accuracy_rate).to eq(85.5)
    end

    it 'creates successfully with all associations' do
      rank = RankMaster.create!(name: 'Silver')
      comment = ResultCommentMaster.create!(comment: 'Good effort')
      detaile = ResultDetaileMaster.create!(detaile: 'Analysis complete')

      result = ResultStringCount.create!(
        rank_master: rank,
        result_comment_master: comment,
        result_detaile_master: detaile,
        string_count: 100,
        accuracy_rate: 92.3
      )

      expect(result).to be_persisted
      expect(result.rank_master).to eq(rank)
      expect(result.result_comment_master).to eq(comment)
      expect(result.result_detaile_master).to eq(detaile)
    end

    it 'handles nil associations gracefully' do
      result = ResultStringCount.new(
        rank_master: nil,
        result_comment_master: nil,
        result_detaile_master: nil
      )

      expect(result).to be_valid
      expect(result.rank).to be_nil
      expect(result.comment).to be_nil
      expect(result.detaile).to be_nil
    end
  end

  describe 'database integrity' do
    it 'has timestamps' do
      result = ResultStringCount.create!

      expect(result.created_at).to be_present
      expect(result.updated_at).to be_present
    end

    it 'updates timestamp on modification' do
      result = ResultStringCount.create!(string_count: 50)
      original_updated_at = result.updated_at

      sleep(0.01) # Ensure time difference
      result.update!(string_count: 75)

      expect(result.updated_at).to be > original_updated_at
    end
  end

  describe 'association behavior' do
    let(:rank) { RankMaster.create!(name: 'Bronze') }
    let(:result) { ResultStringCount.create!(rank_master: rank) }

    it 'maintains association after reload' do
      result.reload
      expect(result.rank).to eq(rank)
      expect(result.rank.name).to eq('Bronze')
    end

    it 'allows association updates' do
      new_rank = RankMaster.create!(name: 'Platinum')
      result.update!(rank_master: new_rank)

      expect(result.rank).to eq(new_rank)
      expect(result.rank.name).to eq('Platinum')
    end

    it 'handles association deletion gracefully with optional: true' do
      rank.destroy
      result.reload

      # Due to optional: true, this should not raise an error
      expect { result.rank }.not_to raise_error
    end
  end
end