module NameJudgment

    #　文字のunicode変換
    def change_unicode_point(string)
        arr_code = string.force_encoding("utf-8").unpack("U*")
        unicode = Array.new
        arr_code.each_with_index do |code, i|
            unicode[i] = sprintf("%#x", code)
            unicode[i][0, 2] = ''
            unicode[i].upcase!
        end
        unicode
    end

    # 総画数取得
    def all_count_get(unicode)
        StringCount.where(unicode: unicode).pluck(:count).sum
    end

    def name_count_result(count)
        result_count = ResultStringCount.find(count)

        result_data ={
            count: count,
            rank: result_count.rank.rank,
            comment: result_count.comment.comment,
            detail: result_count.detaile.detaile,
        }

        result_data
    end
    
end