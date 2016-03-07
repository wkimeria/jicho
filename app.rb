########
# app.rb
#
Bundler.require :web
Bundler.require :development if development?

require 'google_cloud_vision'
require "sinatra/config_file"



require 'sinatra/base'

class JichoApp < Sinatra::Base
  register Sinatra::ConfigFile
  config_file 'config/config.yml'

  set :root, File.dirname(__FILE__)

  enable :sessions

  get '/style.css' do
    scss :style
  end

  $submission_count = 0

  get '/' do
    $submission_count ||= 0
    @submission_limit = settings.submission_limit

    puts "1 ----------------- #{@submission_count} --- #{@submission_limit}"

    @labels = []
    @scores = []
    haml(:index, :locals => {:labels => @labels,
                             :scores => @scores,
                             :submission_count => $submission_count,
                             :submission_limit => @submission_limit})
  end

  post "/" do

    @submission_limit = settings.submission_limit
    puts "2 ----------------- #{$submission_count} --- #{@submission_limit}"

    if params['image_file'] && $submission_count <= settings.submission_limit

      tmp_path = params['image_file'][:tempfile].to_path.to_s
      label_response = GoogleCloudVision::Classifier.new(settings.api_key,
                                                         [
                                                             {image: tmp_path, detection: 'LABEL_DETECTION', max_results: 10}
                                                         ]).response

      if label_response['responses']
        @labels = []
        @scores = []
        label_response['responses'][0]['labelAnnotations'].each do |i|
          @labels << i['description']
          @scores << i['score']
        end

        $submission_count = $submission_count + 1

        haml(:index, :locals => {:labels => @labels,
                                 :scores => @scores,
                                 :submission_count => $submission_count,
                                 :submission_limit => @submission_limit})
      end
    else

    end
  end

  not_found do
    haml :'404'
  end
end