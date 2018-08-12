require 'cgi'
require 'kconv'
require 'open-uri'
require 'rss'

TITLE = 'WWW.SBCR.JP トピックス'
URL = 'https://www.sbcr.jp/topics/'
PAGE_SRC = open('https://www.sbcr.jp/topics/', &:read).toutf8

def parse(page_src)
  dates = page_src.scan(/(\d+)年(\d+)月(\d+| \d+)日<br \/>/)
  url_titles = page_src.scan(/^<a href="(.+?)">([^<].+?)<\/a><br \/>/)
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

def format_rss(title, url, url_title_time_ary)
  RSS::Maker.make('2.0') do |maker|
    maker.channel.updated = Time.now.to_s
    maker.channel.link = url
    maker.channel.title = title
    maker.channel.description = title
    url_title_time_ary.each do |aurl, atitile, atime|
      maker.items.new_item do |item|
        item.link = aurl
        item.title = atitile
        item.updated = atime
        item.description = atitile
      end
    end
  end
end

formatter = if ARGV.first == 'format_rss'
              :format_rss
            else
              :format_text
            end

puts send(formatter, TITLE, URL, parse(PAGE_SRC))
