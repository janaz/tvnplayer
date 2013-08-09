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
  LOCAL_IP = '0.0.0.0'

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
      @episodes = request.parsed_response['items'].map do |e|
        Episode.from_json(e)
      end
    end

    private

    def request
      c = HTTPClient.new
      c.socket_local=HTTPClient::Site.new(URI("tcp://#{LOCAL_IP}:0"))
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

    def url

    end

    def name
      "#{@title.titleize}.S%02dE%02d".gsub(' ','.') % [@season_id, @episode_in_season]
    end

    def file_name
      "#{name}.mp4"
    end

    def data
      @data ||= request.parsed_response
    end

    private


    def request
      c = HTTPClient.new
      c.socket_local=HTTPClient::Site.new(URI("tcp://#{LOCAL_IP}:0"))
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
