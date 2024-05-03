# frozen_string_literal: true

class KanbanDateHelper
  def self.days_between(date1, date2)
    raise(TypeError) unless date1.is_a?(DateTime) && date2.is_a?(DateTime)

    start = [date1, date2].min
    finish = [date1, date2].max
    days = 0
    while start < finish
      days += 1
      start += 1.day
    end

    days
  end
end
