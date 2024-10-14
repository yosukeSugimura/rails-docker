require 'rails_helper'

RSpec.describe NameJudgment, type: :module do
  let(:dummy_class) { Class.new { include NameJudgment } }
  let(:dummy_instance) { dummy_class.new }

  describe '#change_unicode_point' do
    it 'returns an array of Unicode points in hexadecimal' do
      expect(dummy_instance.change_unicode_point("吉")).to eq(["5409"])
    end

    it 'raises an error for invalid encoding' do
      invalid_string = "\xC0".force_encoding("UTF-8")
      expect { dummy_instance.change_unicode_point(invalid_string) }.to raise_error(ArgumentError, "Invalid string encoding")
    end
  end

  describe '#all_count_get' do
    it 'returns the total count for given unicode' do
      # モックでwhereメソッドの返り値に対して、sumメソッドを呼び出す
      string_counts = double("ActiveRecord_Relation")
      allow(StringCount).to receive(:where).with(unicode: "5409").and_return(string_counts)
      allow(string_counts).to receive(:sum).with(:count).and_return(10)

      expect(dummy_instance.all_count_get("5409")).to eq(10)
    end
  end


  describe '#name_count_result' do
    it 'returns name result when valid count is provided' do
      rank = double(rank: 'A')
      comment = double(comment: 'Good fortune')
      detail = double(detaile: 'Detailed info')
      result = double(rank: rank, comment: comment, detaile: detail)

      allow(ResultStringCount).to receive(:find_by).with(id: 10).and_return(result)
      expect(dummy_instance.name_count_result(10)).to eq({
        count: 10,
        rank: 'A',
        comment: 'Good fortune',
        detail: 'Detailed info'
      })
    end

    it 'returns an error when result is not found' do
      allow(ResultStringCount).to receive(:find_by).with(id: 999).and_return(nil)
      expect(dummy_instance.name_count_result(999)).to eq({ error: "Result not found" })
    end
  end
end
