require 'cgi'
require 'kconv'
require 'open-uri'
require 'rss'
require 'webrick'
require 'pry'

TITLE = 'WWW.SBCR.JP トピックス'
URL = 'https://www.sbcr.jp/topics/'

class Site
  def initialize(url:'', title:'')
    @url = url
    @title = title
  end

  attr_reader :url, :title

  def page_src
    @page_src ||= open(url, &:read).toutf8
  end

  def output(formatter_klass)
    formatter_klass.new(self).format(parse)
  end
end

class SbcrTopics < Site
  def parse
    dates = page_src.scan(/(\d+)年(\d+)月(\d+| \d+)日<br \/>/)
    url_titles = page_src.scan(/^<a href="(.+?)">([^<].+?)<\/a><br \/>/)
    url_titles.zip(dates).map do |url_title, ymd|
      url, title = *url_title
      [CGI.unescapeHTML(url), CGI.unescapeHTML(title), Time.local(*ymd)]
    end
  end
end

class Formatter
  def initialize(site)
    @url = site.url
    @title = site.title
  end

  attr_reader :url, :title
end

class TextFormatter < Formatter
  def format(url_title_time_ary)
    s = "Ttle: #{title}\nURL: #{url}\n\n"
    url_title_time_ary.each do |aurl, atitile, atime|
      s << "- (#{atime})#{atitile}\n"
      s << "   #{aurl}\n"
    end
    s
  end
end

class RSSFormatter < Formatter
  def format(url_title_time_ary)
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
end

class RSSServlet < WEBrick::HTTPServlet::AbstractServlet
  def do_GET(req, res)
    klass, opts = @options
    res.body = klass.new(opts).output(RSSFormatter).to_s
    res.content_type = 'application/xml; charset=utf-8'
  end
end

def start_server
  srv = WEBrick::HTTPServer.new(Port: 3000, BindAddress: '127.0.0.1')
  srv.mount('/rss.xml', RSSServlet, SbcrTopics, url: URL, title: TITLE)
  trap('INT') { srv.shutdown }
  srv.start
end

if ARGV.first == 'server'
  start_server
else
  site = SbcrTopics.new(url: URL, title: TITLE)
  ARGV.first == 'format_rss' ? puts(site.output RSSFormatter) : puts(site.output TextFormatter)
end
