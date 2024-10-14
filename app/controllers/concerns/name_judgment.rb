module NameJudgment
    # 文字の Unicode 変換
    def change_unicode_point(string)
      unless string.valid_encoding?
        raise ArgumentError, "Invalid string encoding"
      end
  
      string.unpack("U*").map { |code| code.to_s(16).upcase }
    end
  
    # 総画数取得
    def all_count_get(unicode)
      StringCount.where(unicode: unicode).sum(:count)
    end
  
    # 名前の結果取得
    def name_count_result(count)
      result_count = ResultStringCount.find_by(id: count)
      return { error: "Result not found" } unless result_count
  
      {
        count: count,
        rank: result_count.rank.rank,
        comment: result_count.comment.comment,
        detail: result_count.detaile.detaile,
      }
    end
  end
  