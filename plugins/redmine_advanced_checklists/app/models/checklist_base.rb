# frozen_string_literal: true

class ChecklistBase < ActiveRecord::Base
  self.abstract_class = true

  TYPE_USUAL = 'Usual'
  TYPE_PERSONAL = 'Assigned'

  include Redmine::SafeAttributes

  belongs_to :created_by,
             :class_name => 'User',
             :foreign_key => 'created_by_id'

  validates :title,
            presence: true,
            length: {maximum: 50}
  validates :sort_order,
            presence: true,
            numericality: true
  validates :list_type,
            presence: true

  def set_title(data)
    self.title = data
  end

  def set_deleted(data)
    self.deleted = data
  end

  def set_list_type(list_type)
    self.list_type = list_type
  end

  def is_type_personal?
    # rubocop:disable Lint/DuplicateBranch
    case list_type
    when ChecklistBase::TYPE_USUAL
      false
    else
      false
    end
    # rubocop:enable Lint/DuplicateBranch
  end
end
