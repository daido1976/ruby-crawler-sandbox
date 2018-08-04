require 'cgi'

def parse(page_source)
  dates = page_source.scan(/(\d+)年(\d+)月(\d+| \d+)日<br \/>/)
  url_titles = page_source.scan(/^<a href="(.+?)">([^<].+?)<\/a><br \/>/)
  url_titles.zip(dates).map do |url_title, ymd|
    url, title = *url_title
    [CGI.unescapeHTML(url), CGI.unescapeHTML(title), Time.local(*ymd)]
  end
end

def format_text(title, url, url_title_time_ary)
  s = "Ttle: #{title}\nURL: #{url}\n\n"
  url_title_time_ary.each do |aurl, atitile, atime|
    s << "- (#{atime})#{atitile}\n"
    s << "   #{aurl}\n"
  end
  s
end

TITLE = 'WWW.SBCR.JP トピックス'
URL = 'https://www.sbcr.jp/topics/'
page_source = `/usr/local/bin/wget -q -O- https://www.sbcr.jp/topics/`

puts format_text(TITLE, URL, parse(page_source))
