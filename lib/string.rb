class String
  # Thanks to http://stackoverflow.com/questions/5661466/test-if-string-is-a-number-in-ruby-on-rails
  def number?
    return true if self =~ /^\d+$/
    true if Float(self) rescue false
  end
end
