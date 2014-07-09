module ApplicationHelper
  def current_search
    params[:search] || JSON.parse(cookies[:search_history] || '[]').last || String.new
  end
end
