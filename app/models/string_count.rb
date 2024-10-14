class StringCount < ApplicationRecord
    scope :by_unicode, ->(unicode) { where(unicode: unicode) }
end
