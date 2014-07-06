class ArabicRoot < ActiveRecord::Base
  belongs_to :book
  
  # belongs_to :page

  def page
    Page.find(self.book, self.start_page)
  end
  
  # custom finder
  
  def self.find_by_search_string(string)
    string = remove_vocalisation_from_arabic_string(string)
    return self.find_by_name(string)
=begin
    else
      # No entry point has been found with the search string as-is. 
      # The remaining possibilities:
      # - user has entered three radicals
      # - user has entered four radicals
      # - user has entered a word
      # - user has entered something nonsensical
      if r = ArabicRoot.find_by_name(simplify_hamzas_in_arabic_string(string))
        # The latter case is the easiest, as only extraneous hamzas need to be stripped
        # from the first letter and inner-word hamzas as well as hamzas on the last letter
        # need to be reduced to free-standing ones.
        return Page.find(book, r.start_page)
      elsif r = ArabicRoot.find_by_name(extract_root_from_arabic_string(string))
        # The only thing left to try is to make an attempt at extracting the root ourselves.
        return Page.find(book, r.start_page)
      end
    end
=end
  end
  
  private
  
  def self.remove_vocalisation_from_arabic_string(string)
    # TODO: Implement me!
    string
  end

  def self.simplify_hamzas_in_arabic_string(string)
    # TODO: Implement me!
    string
  end

  def self.extract_root_from_arabic_string(string)
    # TODO: Implement me!
    string
  end  
end
  
  
