# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ResultDetaileMaster, type: :model do
  describe 'creation and persistence' do
    it 'creates a result detaile master successfully' do
      detaile = ResultDetaileMaster.create!(detaile: 'Detailed analysis of performance')

      expect(detaile).to be_persisted
      expect(detaile.detaile).to eq('Detailed analysis of performance')
    end

    it 'has timestamps' do
      detaile = ResultDetaileMaster.create!(detaile: 'Sample detail')

      expect(detaile.created_at).to be_present
      expect(detaile.updated_at).to be_present
    end
  end

  describe 'detail content handling' do
    it 'handles comprehensive detailed information' do
      comprehensive_detail = 'Performance metrics: Speed 95%, Accuracy 87%, Consistency 92%. Areas for improvement: Focus on accuracy in complex scenarios.'
      detaile = ResultDetaileMaster.create!(detaile: comprehensive_detail)

      expect(detaile.detaile).to eq(comprehensive_detail)
    end

    it 'handles structured data formats' do
      structured_detail = "Category A: 85%\nCategory B: 92%\nCategory C: 78%\nOverall: 85%"
      detaile = ResultDetaileMaster.create!(detaile: structured_detail)

      expect(detaile.detaile).to eq(structured_detail)
      expect(detaile.detaile.lines.count).to eq(4)
    end

    it 'handles empty details' do
      detaile = ResultDetaileMaster.create!(detaile: '')
      expect(detaile.detaile).to eq('')
    end

    it 'handles special characters and formatting' do
      formatted_detail = "Results:\n• Speed: ★★★★☆\n• Accuracy: ★★★☆☆\n• Overall: 🎯 Good job!"
      detaile = ResultDetaileMaster.create!(detaile: formatted_detail)

      expect(detaile.detaile).to eq(formatted_detail)
    end
  end

  describe 'database operations' do
    let!(:detaile1) { ResultDetaileMaster.create!(detaile: 'Original detailed analysis') }
    let!(:detaile2) { ResultDetaileMaster.create!(detaile: 'Alternative analysis') }

    it 'updates detaile content' do
      detaile1.update!(detaile: 'Updated comprehensive analysis')
      expect(detaile1.reload.detaile).to eq('Updated comprehensive analysis')
    end

    it 'deletes detaile successfully' do
      expect { detaile1.destroy! }.to change(ResultDetaileMaster, :count).by(-1)
    end

    it 'finds detaile by content' do
      found_detaile = ResultDetaileMaster.find_by(detaile: 'Alternative analysis')
      expect(found_detaile).to eq(detaile2)
    end
  end

  describe 'associations' do
    let(:detaile) { ResultDetaileMaster.create!(detaile: 'Test detailed information') }

    it 'can be associated with result string counts' do
      result = ResultStringCount.create!(result_detaile_master: detaile)
      expect(result.result_detaile_master).to eq(detaile)
      expect(result.detaile).to eq(detaile) # Test alias
    end
  end

  describe 'large content handling' do
    it 'handles very long detailed content' do
      long_detail = 'Detailed analysis: ' + ('A' * 5000)
      detaile = ResultDetaileMaster.create!(detaile: long_detail)

      expect(detaile.detaile).to eq(long_detail)
      expect(detaile.detaile.length).to eq(long_detail.length)
    end

    it 'handles content with various data types' do
      mixed_content = <<~DETAIL
        Numerical Data: 123.45
        Boolean Data: true/false
        Date Data: 2023-10-15
        JSON Data: {"score": 85, "grade": "B+"}
        URL Data: https://example.com/report
        Email Data: user@example.com
      DETAIL

      detaile = ResultDetaileMaster.create!(detaile: mixed_content.strip)
      expect(detaile.detaile).to include('Numerical Data')
      expect(detaile.detaile).to include('Boolean Data')
      expect(detaile.detaile).to include('JSON Data')
    end
  end

  describe 'query operations' do
    before do
      ResultDetaileMaster.create!(detaile: 'Performance excellent in all areas')
      ResultDetaileMaster.create!(detaile: 'Good performance with room for improvement')
      ResultDetaileMaster.create!(detaile: 'Average performance, needs focus on accuracy')
    end

    it 'can search details containing specific keywords' do
      performance_results = ResultDetaileMaster.where('detaile LIKE ?', '%performance%')
      expect(performance_results.count).to eq(3)

      excellent_results = ResultDetaileMaster.where('detaile LIKE ?', '%excellent%')
      expect(excellent_results.count).to eq(1)
    end

    it 'can order details by length' do
      ordered_by_length = ResultDetaileMaster.order('LENGTH(detaile) DESC')
      lengths = ordered_by_length.pluck(:detaile).map(&:length)

      expect(lengths).to eq(lengths.sort.reverse)
    end
  end

  describe 'edge cases and validation' do
    it 'handles details with control characters' do
      control_char_detail = "Line 1\r\nLine 2\tTabbed\0Null char"
      detaile = ResultDetaileMaster.create!(detaile: control_char_detail)

      expect(detaile.detaile).to eq(control_char_detail)
    end

    it 'preserves formatting in detailed content' do
      formatted_content = <<~CONTENT
        # Analysis Report

        ## Summary
        - Point 1
        - Point 2

        ## Details
        1. First item
        2. Second item
      CONTENT

      detaile = ResultDetaileMaster.create!(detaile: formatted_content.strip)
      expect(detaile.detaile).to include('# Analysis Report')
      expect(detaile.detaile).to include('## Summary')
    end
  end
end