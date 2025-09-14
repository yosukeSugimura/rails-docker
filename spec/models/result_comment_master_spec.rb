# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ResultCommentMaster, type: :model do
  describe 'creation and persistence' do
    it 'creates a result comment master successfully' do
      comment = ResultCommentMaster.create!(comment: 'Excellent work!')

      expect(comment).to be_persisted
      expect(comment.comment).to eq('Excellent work!')
    end

    it 'has timestamps' do
      comment = ResultCommentMaster.create!(comment: 'Good effort')

      expect(comment.created_at).to be_present
      expect(comment.updated_at).to be_present
    end
  end

  describe 'comment content handling' do
    it 'handles long comments' do
      long_comment = 'A' * 1000
      comment = ResultCommentMaster.create!(comment: long_comment)

      expect(comment.comment).to eq(long_comment)
      expect(comment.comment.length).to eq(1000)
    end

    it 'handles special characters and unicode' do
      special_comment = 'Great job! 🎉 Keep it up! 👍'
      comment = ResultCommentMaster.create!(comment: special_comment)

      expect(comment.comment).to eq(special_comment)
    end

    it 'handles multiline comments' do
      multiline_comment = "Line 1\nLine 2\nLine 3"
      comment = ResultCommentMaster.create!(comment: multiline_comment)

      expect(comment.comment).to eq(multiline_comment)
      expect(comment.comment.lines.count).to eq(3)
    end

    it 'handles empty comments' do
      comment = ResultCommentMaster.create!(comment: '')
      expect(comment.comment).to eq('')
    end
  end

  describe 'database operations' do
    let!(:comment1) { ResultCommentMaster.create!(comment: 'Original comment') }
    let!(:comment2) { ResultCommentMaster.create!(comment: 'Another comment') }

    it 'updates comment content' do
      comment1.update!(comment: 'Updated comment')
      expect(comment1.reload.comment).to eq('Updated comment')
    end

    it 'deletes comment successfully' do
      expect { comment1.destroy! }.to change(ResultCommentMaster, :count).by(-1)
    end

    it 'finds comment by content' do
      found_comment = ResultCommentMaster.find_by(comment: 'Another comment')
      expect(found_comment).to eq(comment2)
    end
  end

  describe 'associations' do
    let(:comment) { ResultCommentMaster.create!(comment: 'Test comment') }

    it 'can be associated with result string counts' do
      result = ResultStringCount.create!(result_comment_master: comment)
      expect(result.result_comment_master).to eq(comment)
      expect(result.comment).to eq(comment) # Test alias
    end
  end

  describe 'edge cases' do
    it 'handles comments with only whitespace' do
      whitespace_comment = ResultCommentMaster.create!(comment: '   \n\t   ')
      expect(whitespace_comment.comment).to eq('   \n\t   ')
    end

    it 'handles comments with HTML-like content' do
      html_comment = ResultCommentMaster.create!(comment: '<script>alert("test")</script>')
      expect(html_comment.comment).to eq('<script>alert("test")</script>')
    end

    it 'handles comments with JSON-like content' do
      json_comment = ResultCommentMaster.create!(comment: '{"status": "success", "message": "done"}')
      expect(json_comment.comment).to eq('{"status": "success", "message": "done"}')
    end
  end

  describe 'query operations' do
    before do
      ResultCommentMaster.create!(comment: 'Excellent performance')
      ResultCommentMaster.create!(comment: 'Good effort')
      ResultCommentMaster.create!(comment: 'Needs improvement')
    end

    it 'can search comments containing specific text' do
      results = ResultCommentMaster.where('comment LIKE ?', '%performance%')
      expect(results.count).to eq(1)
      expect(results.first.comment).to include('performance')
    end

    it 'can order comments alphabetically' do
      ordered_comments = ResultCommentMaster.order(:comment).pluck(:comment)
      expect(ordered_comments).to eq(ordered_comments.sort)
    end
  end
end