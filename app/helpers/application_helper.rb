module ApplicationHelper
  def markdown(text)
    return "" if text.blank?

    # Usa Kramdown para convertir Markdown a HTML seguro
    Kramdown::Document.new(text).to_html.html_safe
  end
end
