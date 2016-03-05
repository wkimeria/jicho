#require 'google_cloud_vision/version'
require 'base64'
require 'net/http'
require 'json'

# simple wrapper for Google Cloud Vision API
module GoogleCloudVision
  # classifier for face, text and label detection
  class Classifier
    attr_reader :response

    def initialize(api_key, images)
      @url = "https://vision.googleapis.com/v1/images:annotate?key=#{api_key}"
      @images = images
      call_vision_api(requests(images))
    end

    private

    def requests(images)
      data = { requests: [] }
      images.each do |image|
        data[:requests] << request(image)
      end
      data.to_json
    end

    def request(image)
      {
          image: {
              content: Base64.encode64(File.open(image[:image], 'rb').read)
          },
          features: {
              type: image[:detection],
              maxResults: image[:maxResults] || 1
          }
      }
    end

    def call_vision_api(data)
      url = URI(@url)
      req = Net::HTTP::Post.new(url, initheader = { 'Content-Type' =>'application/json' })
      req.body = data
      res = Net::HTTP.new(url.host, url.port)
      res.use_ssl = true
      res.start do |http|
        resp = http.request(req)
        json = JSON.parse(resp.body)
        @response = json
      end
    end
  end
end