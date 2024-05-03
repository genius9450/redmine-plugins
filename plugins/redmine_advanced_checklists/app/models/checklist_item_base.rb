# frozen_string_literal: true

class ChecklistItemBase < ActiveRecord::Base
  self.abstract_class = true

  include Redmine::SafeAttributes

  belongs_to :created_by,
             :class_name => 'User',
             :foreign_key => 'created_by_id'
  belongs_to :assigned_to,
             :class_name => 'Principal',
             :foreign_key => 'assigned_to_id'

  validates :title,
            presence: true,
            length: {maximum: 2000}
  validates :sort_order,
            presence: true,
            numericality: true
  validates :assigned_to,
            presence: true,
            if: :is_assigned_to_required?

  def set_order(data)
    count = 0
    questionlist.items.each do |i|
      count += 1 if count == data
      if id == i.id
        self.sort_order = data
        count += (count < data ? -1 : 1)
      else
        i.sort_order = count
      end

      i.save(touch: false)
      count += 1
    end
  end

  def set_title(data)
    self.title = data
  end

  def set_deleted(data)
    self.deleted = data
  end
end
