class ArabicRoot < ActiveRecord::Base
  default_scope {order('start_page ASC')}

  belongs_to :book

  # belongs_to :page

  def page
    Page.find(self.book, self.start_page)
  end
  
  # custom finder
  
  def self.find_by_search_string(string)
    return self.find_by_name(string)
  end
end
  
  
