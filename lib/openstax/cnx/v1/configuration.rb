OpenStax::Cnx::V1::Configuration = Struct.new :archive_url_base, :webview_url_base do
  alias :archive_url_base_setter :archive_url_base=
  alias :webview_url_base_setter :webview_url_base=

  def archive_url_base=(url)
    uri = Addressable::URI.parse(url)
    raise "Invalid CNX archive URL: #{url}" if uri.nil? || uri.host.nil?

    uri.scheme = 'https'
    self.archive_url_base_setter uri.to_s

    uri.host = uri.host.sub(/archive[\.-]?/, '')
    self.webview_url_base_setter uri.to_s
  end

  def webview_url_base=(url)
    uri = Addressable::URI.parse(url)
    raise "Invalid CNX webview URL: #{url}" if uri.nil? || uri.host.nil?

    uri.scheme = 'https'
    self.webview_url_base_setter uri.to_s

    uri.host = "archive-#{uri.host}".sub('archive-cnx', 'archive.cnx')
    self.archive_url_base_setter uri.to_s
  end
end
