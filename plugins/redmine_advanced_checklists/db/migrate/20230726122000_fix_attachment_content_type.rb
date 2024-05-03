class FixAttachmentContentType < ActiveRecord::Migration[5.2]

  def change
    execute "UPDATE attachments SET content_type = REPLACE(content_type, '%2F', '/') WHERE content_type LIKE '%2F%'"
  end

end
