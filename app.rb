Bundler.require :web
Bundler.require :development if development?

require 'google_cloud_vision'
require "sinatra/config_file"
require 'sinatra/base'

class JichoApp < Sinatra::Base
  register Sinatra::ConfigFile
  config_file 'config/config.yml'

  set :root, File.dirname(__FILE__)

  $submission_count = 0

  get '/style.css' do
    scss :style
  end

  get '/' do
    return_response
  end

  post "/" do
    if params['image_file'] && $submission_count <= settings.submission_limit

      tmp_path = params['image_file'][:tempfile].to_path.to_s

      begin
        labels, scores =  get_labels_and_scores(tmp_path)
        if labels && scores
          $submission_count = $submission_count + 1
          return_response(labels, scores)
        end
      rescue => e
        return_response([], [], "An error occured fetching the labels for image")
      end
    else

    end
  end

  not_found do
    haml :'404'
  end

  def return_response(labels = [], scores = [], error_message = nil)
    haml(:index, :locals => {:labels => labels,
                             :scores => scores,
                             :submission_count => $submission_count,
                             :submission_limit => settings.submission_limit,
                             :error_message => error_message})
  end

  def get_labels_and_scores(image_path)
    label_response = GoogleCloudVision::Classifier.new(settings.api_key,
         [
             {image: image_path, detection: 'LABEL_DETECTION', max_results: 10}
         ]).response

    if label_response['error']
      puts "An error occurred #{label_response['error']}"
      raise Error "An error occured"
    end

    @labels = []
    @scores = []

    if label_response['responses'] && label_response['responses'][0]['labelAnnotations']
      label_response['responses'][0]['labelAnnotations'].each do |i|
        @labels << i['description']
        @scores << i['score']
      end
    end
    return @labels, @scores
  end

end