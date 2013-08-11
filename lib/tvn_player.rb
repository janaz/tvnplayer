require 'httpclient'
require 'active_support/core_ext'
require 'json'

module TvnPlayer
  API_URL = "https://api.tvnplayer.pl/api/"
  BASE_PARAMS = {
      :platform => 'ConnectedTV',
      :terminal => 'Samsung',
      :format => 'json',
      :sort => 'newest',
      :authKey => 'ba786b315508f0920eca1c34d65534cd',
      :m => 'getItems',
  }
  PL_IP = '192.168.3.12'

  class Series
    class << self
      def kuchenne_rewolucje(season_id)
        Series.new(114, season_id)
      end
    end

    def initialize series_id, season_id
      @series_id = series_id
      @season_id = season_id
    end

    def episodes
      @episodes ||= request['items'].map do |e|
        Episode.from_json(e)
      end
    end

    def download!(destination)
      episodes.each do |e| 
        begin
          filename = File.join(destination, e.file_name)
          unless File.exists?(filename)
            puts "Downloading #{e.file_name} from #{e.stream_url}"
            system("curl -vvv --trace-time -L -o #{Shellwords.escape(filename)} #{Shellwords.escape(e.stream_url)}")
          end
        rescue
        end	   
      end 
    end

    private

    def request
      c = HTTPClient.new
      c.socket_local=HTTPClient::Site.new(URI("tcp://#{PL_IP}:0"))
      resp = c.get(API_URL, req_options[:query], req_options[:headers])
      JSON.parse(resp.body)
    end

    def req_options
      {
          :query => req_params,
          :format => :json,
          :headers => {
              "Accept" => "application/json, text/javascript, */*; q=0.01",
              "Connection" => "close",
              "X-Requested-With" => "XMLHttpRequest",
          }
      }
    end

    def req_params
      BASE_PARAMS.merge(:type => 'series', :id => @series_id, :season => @season_id, :limit => 1000, :page => 1)
    end

  end

  class Episode
    class << self
      def from_json(params)
        new(params)

      end
    end

    def initialize(json)
      @episode_id = json['id'].to_i
      @season_id = json['season'].to_i
      @episode_in_season = json['episode'].to_i
      @title = json['title']
    end


    def name
      "#{@title.titleize}.S%02dE%02d".gsub(' ','.') % [@season_id, @episode_in_season]
    end

    def file_name
      "#{name}.mp4"
    end

    def variants
      data['item']['videos']['main']['video_content']
    end

    def variant(quality)
      variants.select{|v| v['profile_name'] == quality}.first
    end

    def data
      @data ||= request
    end

    def hq_url
      bestq = ["Bardzo wysoka", "Wysoka", "Standard"].find{|q| variant(q)}
      variant(bestq)['url'] if bestq
    end

    def stream_url
      return unless hq_url
      @stream_url ||= begin
        c = HTTPClient.new
        c.socket_local=HTTPClient::Site.new(URI("tcp://#{PL_IP}:0"))
        resp = c.get(hq_url, nil, req_options[:headers])
        resp.body
      end
    end

    private


    def request
      c = HTTPClient.new
      c.socket_local=HTTPClient::Site.new(URI("tcp://#{PL_IP}:0"))
      resp = c.get(API_URL, req_options[:query], req_options[:headers])
      JSON.parse(resp.body)
    end

    def req_options
      {
          :query => req_params,
          :format => :json,
          :headers => {
              "Accept" => "application/json, text/javascript, */*; q=0.01",
              "Connection" => "close",
              "X-Requested-With" => "XMLHttpRequest",
          }
      }
    end

    def req_params
      BASE_PARAMS.merge(:type => 'episode', :id => @episode_id, :v => '2.0', :m => 'getItem',
                        :deviceScreenHeight => 1080, :deviceScreenWidth => 1920)
    end

  end
end
