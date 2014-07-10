module ApplicationHelper
  def current_search
    last_search
  end

  def last_search
    JSON.parse(cookies[:search_history]).last unless cookies[:search_history].blank?
  end
end
