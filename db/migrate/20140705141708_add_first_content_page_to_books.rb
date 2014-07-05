class AddFirstContentPageToBooks < ActiveRecord::Migration
  def change
    add_column :books, :first_content_page, :integer
  end
end
