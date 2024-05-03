# frozen_string_literal: true

class KanbanIssueBlockHistoryCollector
  attr_reader :history, :durations

  def initialize(issue)
    @issue = issue
    @history = []
    @durations = {total: 0, current: 0}
    fill_data
  end

  def durations_in_minutes
    @durations.transform_values { |v| (v / 60.0).round }
  end

  def durations_in_hours
    @durations.transform_values { |v| (v / 3600.0).round }
  end

  def durations_in_days
    @durations.transform_values { |v| (v / 86_400.0).round }
  end

private

  def fill_data
    current_duration = 0

    item = {who_started: nil, start: nil, finish: nil, duration: 0, text: nil, who_finished: nil, block_issue_id: nil}
    is_val_changed = false
    block_reason_details.each do |entry|
      detail_entry = entry.details.where(prop_key: :block_reason).first
      is_val_changed = detail_entry.value.present? && detail_entry.old_value.present?
      if (detail_entry.value.present? && detail_entry.old_value.blank?) || is_val_changed
        if item[:start].nil?
          item[:who_started] = entry.user.name
          item[:start] = entry.created_on
          item[:text] = detail_entry.value
        elsif is_val_changed
          item[:finish] = entry.created_on
          item[:duration] = (item[:finish] - item[:start]).round
          item[:who_finished] = entry.user.name

          @durations[:total] += item[:duration]
          @history << item.clone

          item[:who_started] = entry.user.name
          item[:start] = entry.created_on
          item[:finish] = nil
          item[:duration] = 0
          item[:text] = detail_entry.value
          item[:who_finished] = nil
        end
      elsif detail_entry.value.blank? && detail_entry.old_value.present?
        item[:finish] = entry.created_on
        item[:duration] = (item[:finish] - item[:start]).round if item[:start].present?
        item[:who_finished] = entry.user.name
        item[:text] = detail_entry.old_value unless item[:text].present?
        @durations[:total] += item[:duration]
        @history << item.clone

        item[:who_started] = nil
        item[:start] = nil
        item[:finish] = nil
        item[:duration] = 0
        item[:text] = nil
        item[:who_finished] = nil
      end
    end
    if item[:start].present? && item[:who_started].present? && item[:text].present? && item[:finish].nil?
      item[:duration] = (Time.current - item[:start]).round
      current_duration = item[:duration]
      @history << item.clone
    end

    item = {who_started: nil, start: nil, finish: nil, duration: 0, text: nil, who_finished: nil, block_issue_id: nil}
    rel_blocked_details.each do |entry|
      detail_entry = entry.details.where('property = ? AND prop_key = ?', 'relation', 'blocked').first
      if detail_entry.value.present? && detail_entry.old_value.blank?
        block_issue = Issue.find(detail_entry.value)
        if block_issue.present?
          item[:who_started] = entry.user.name
          item[:start] = entry.created_on
          item[:text] = block_issue.subject
          item[:block_issue_id] = block_issue.id
          if block_issue.closed?
            closing_detail = JournalDetail
                             .joins(:journal)
                             .where("#{JournalDetail.table_name}.property = 'attr'")
                             .where("#{JournalDetail.table_name}.prop_key = 'status_id'")
                             .where("#{JournalDetail.table_name}.value = ?", block_issue.status.id)
                             .where("#{Journal.table_name}.journalized_id = ?", block_issue.id)
                             .order("#{Journal.table_name}.created_on DESC")
                             .first
            if closing_detail.present?
              item[:finish] = closing_detail.journal.created_on
              item[:duration] = (item[:finish] - item[:start]).round
              item[:who_finished] = closing_detail.journal.user.name
              @durations[:total] += item[:duration]
            end
          end

          @history << item.clone

          item[:who_started] = nil
          item[:start] = nil
          item[:finish] = nil
          item[:duration] = 0
          item[:text] = nil
          item[:who_finished] = nil
          item[:block_issue_id] = nil
        end
      elsif detail_entry.value.blank? && detail_entry.old_value.present?
        h_item_idx = @history.index { |element| element[:block_issue_id] == detail_entry.old_value }
        unless h_item_idx.nil?
          @history[h_item_idx][:finish] = entry.created_on
          @history[h_item_idx][:duration] = (@history[h_item_idx][:finish] - @history[h_item_idx][:start]).round
          @history[h_item_idx][:who_finished] = entry.user.name
          @durations[:total] += @history[h_item_idx][:duration]
        end
      end
    end

    @history.map! do |element|
      if element[:block_issue_id].present? && element[:finish].nil?
        element[:duration] = (Time.current - element[:start]).round
        current_duration = element[:duration] if element[:duration] > current_duration
      end

      element
    end

    @durations[:current] = current_duration
    @durations[:total] += @durations[:current]

    @history.sort_by! { |h| h[:start] }.reverse!
  rescue StandardError => e
    Rails.logger.error("ERROR fill_data: #{e.message}, trace: #{e.backtrace.inspect}")
  end

  def block_reason_details(sort = :asc)
    return @block_reason_details if @block_reason_details

    @block_reason_details = @issue
                            .journals
                            .joins(:details)
                            .where("#{JournalDetail.table_name}.prop_key = ?", 'block_reason')
                            .order(created_on: sort)
    @block_reason_details
  end

  def rel_blocked_details(sort = :asc)
    return @rel_blocked_details if @rel_blocked_details

    @rel_blocked_details = @issue
                           .journals
                           .joins(:details)
                           .where("#{JournalDetail.table_name}.property = ? AND #{JournalDetail.table_name}.prop_key = ?", 'relation', 'blocked')
                           .order(created_on: sort)
    @rel_blocked_details
  end
end
