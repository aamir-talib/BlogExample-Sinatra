=begin
"<link href= \"#{File.expand_path('/public/css', __FILE__)}\"#{stylesheet}.css\" media=\"screen, projection\" rel=\"stylesheet\" />"
=end

module ApplicationHelpers

  def base_url
    @base_url ||= "#{request.env['rack.url_scheme']}://#{request.env['HTTP_HOST']}"
  end

  def current?(path='/')
    request.path_info==path ? 'current': nil
  end

  def css(*stylesheets)
    stylesheets.map do |stylesheet|
      "<link href=\"#{'/css/' + stylesheet}\" media=\"screen, projection\" rel=\"stylesheet\" />"
    end.join
  end

  def js(*javascripts)
    javascripts.map do |javascript|
      "<script src=\"#{'/js/' + javascript}\"></script>"
    end.join
  end

end