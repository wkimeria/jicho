Bundler.require :web
Bundler.require :development if development?

require './google_cloud_vision.rb'
#require 'google_cloud_vision'
require "sinatra/config_file"
config_file 'config/app.yml'

get '/style.css' do
  scss :style
end

get '/' do
  haml :index
end

# Handle POST-request (Receive and save the uploaded file) or fetch image at specified urp
post "/" do
  if params['image_file']
    # puts params['image_file'][:tempfile].read
    #debugger

    tmp_path = params['image_file'][:tempfile].to_path.to_s
    label_response = GoogleCloudVision::Classifier.new(settings.api_key,
                                           [
                                               {image: tmp_path, detection: 'LABEL_DETECTION', maxResults: 10}
                                           ]).response

    if label_response['responses']
      labels = []
      label_response['responses'][0]['labelAnnotations'].each do |i|
        label = {:label => i['description'], :score => i['score']}
        labels << label
      end
      haml(:index, :locals => {:labels => labels})
    end
  else
    # Throw error
  end
end

not_found do
  haml :'404'
end
