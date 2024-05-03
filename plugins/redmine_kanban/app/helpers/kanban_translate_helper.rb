# frozen_string_literal: true

module KanbanTranslateHelper
  def build_translations
    all = [
      :button_cancel,
      :button_create,
      :button_save,
      :button_edit,
      :button_delete,
      :button_submit,
      :button_clear,
      :button_unlock,

      :label_comment_plural,

      :label_spent_time,

      :label_project,

      :button_log_time,
      :label_search,
      :label_today,
      :label_ago,
      :label_related_issues,
      :field_total_estimated_hours,
      :text_are_you_sure,
      :label_attachment_plural,
      :label_attachment,
      :label_edit_attachments,
      :button_download,
      :button_save_as_template,

      :field_is_private,
      :field_start_date,
      :field_parent_issue,
      :field_name,
      :field_type,
      :field_estimated_hours,
      :field_due_date,
      :field_description,
      :field_priority,
      :field_status,
      :field_assigned_to,
      :field_updated_on,

      :label_added_time_by,
      :label_updated_time,
      :field_filename,

      :actionview_instancetag_blank_option,

      :label_attachment_new,
      :label_item_position,

      :label_board_locked,
      :label_no_data,

      :setting_attachment_max_size,
      :setting_attachment_extensions_denied,
      :setting_attachment_extensions_allowed,

      :notice_issue_update_conflict,

      :label_assigned_to_me_issues,
      :label_subtask_plural,
      :info_my_tasks_button, :info_locked_button,
      :check,

      :errors_error,
      :field_block_reason,
      :error_attachment_too_big,
      :error_attachment_extension_not_allowed,
      :label_issue_new,
      :field_subject,
      :label_checklists_should_be_assigned,
      :field_tracker,
      :field_fixed_version,
      :label_table_view,
      :label_allow_add_issues,
      :label_disable_add_issues,
      :label_total,
      :label_fullscreen,
      :label_issue_watchers,
      :message_total_issues,
      :label_copied,
      :label_history,
      :label_issue_history_notes,
      :label_issue_history_properties,
      :field_remove_block,
      :label_blank_value,
      :hint_issues_count,
      :hint_block_reason,
      :hint_issue_size,
    ]

    @translations = {}
    all.each do |label|
      @translations[label] = I18n.t(label)
    end
    @translations.to_json
  end
end
