# frozen_string_literal: true

class KanbanIssueStatusesCollector
  attr_reader :data

  def initialize(issue)
    @issue = issue
    @data = []
    fill_data
  end

private

  def fill_data
    assignee_id = initial_assignee_id
    @data << detail_object(initial_detail, initial_assignee_id, @issue.created_on)

    issue_details.each do |detail|
      next unless detail.prop_key == 'status_id'

      assignee_id = assignee_for(detail) || assignee_id
      @data << detail_object(detail, assignee_id, detail.journal.created_on)
    end

    @data.each_with_index do |detail, idx|
      detail[:end_time] = @data[idx + 1] ? @data[idx + 1][:journal].created_on : Time.current
      detail[:duration] = detail[:end_time] - detail[:start_time]
    end
  end

  def detail_object(detail, assignee_id, start_time)
    {
      journal: detail.journal,
      status_id: detail.value,
      assigned_to_id: assignee_id,
      start_time: start_time,
      end_time: nil,
      duration: nil
    }
  end

  def assignee_for(detail)
    detail.journal.details.detect { |item| item.prop_key == 'assigned_to_id' }.try(:value)
  end

  def issue_details
    return @issue_details if @issue_details

    @issue_details = @issue.journals.map(&:details).flatten.sort_by { |a| a.journal.created_on }
    @issue_details.unshift
  end

  def first_status_detail
    issue_details.detect { |d| d.prop_key == 'status_id' }
  end

  def initial_assignee_id
    issue_details.detect { |detail| detail.prop_key == 'assigned_to_id' }.try(:old_value) || @issue.assigned_to_id
  end

  def initial_detail
    JournalDetail.new(
      property: 'attr',
      prop_key: 'status_id',
      value: first_status_detail.try(:old_value) || @issue.status.id,
      journal: Journal.new(user: @issue.author, created_on: @issue.created_on)
    )
  end
end
