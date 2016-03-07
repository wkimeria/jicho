Bundler.require :web
Bundler.require :development if development?

require 'google_cloud_vision'
require "sinatra/config_file"
config_file 'config/config.yml'

get '/style.css' do
  scss :style
end

get '/' do
  @labels = []
  @scores = []
  haml(:index, :locals => {:labels => @labels, :scores => @scores})
end

# Handle POST-request (Receive and save the uploaded file) or fetch image at specified urp
post "/" do
  if params['image_file']
    # puts params['image_file'][:tempfile].read
    #debugger

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
      haml(:index, :locals => {:labels => @labels, :scores => @scores})
    end
  else
    # Throw error
  end
end

not_found do
  haml :'404'
end
