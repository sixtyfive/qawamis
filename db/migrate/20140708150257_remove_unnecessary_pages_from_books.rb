class RemoveUnnecessaryPagesFromBooks < ActiveRecord::Migration
  def change
    [:number_of_pages, :created_at, :updated_at, :first_numbered_page].each do |c|
    remove_column :books, c
    end
  end
end
