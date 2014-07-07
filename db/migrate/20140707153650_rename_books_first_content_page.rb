class RenameBooksFirstContentPage < ActiveRecord::Migration
  def change
    rename_column :books, :first_content_page, :first_numbered_page
  end
end
