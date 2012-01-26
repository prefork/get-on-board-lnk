require 'sinatra'
require 'json'
require './otvia'

get '/' do
  "nothing"
end

get '/api/v1/vehicles' do
  json = get_vehicles_by_id.to_json

  callback = params.delete('callback')
  if callback
    content_type :js
    response = "#{callback}(#{json})"
  else
    content_type :json
    response = json
  end
  response
end

get '/api/v1/vehicles/:id' do
  json = get_vehicles_by_id(params[:id]).to_json

  callback = params.delete('callback')
  if callback
    content_type :js
    response = "#{callback}(#{json})"
  else
    content_type :json
    response = json
  end
  response
end

get '/api/v1/routes' do
  json = get_vehicles_by_route.to_json

  callback = params.delete('callback')
  if callback
    content_type :js
    response = "#{callback}(#{json})"
  else
    content_type :json
    response = json
  end
  response
end

get '/api/v1/routes/:id' do
  json = get_vehicles_by_route(params[:id]).to_json

  callback = params.delete('callback')
  if callback
    content_type :js
    response = "#{callback}(#{json})"
  else
    content_type :json
    response = json
  end
  response
end

get '/api/v1/shelters' do
  json = get_shelters_by_id.to_json

  callback = params.delete('callback')
  if callback
    content_type :js
    response = "#{callback}(#{json})"
  else
    content_type :json
    response = json
  end
  response
end

get '/api/v1/shelters/:id' do
  json = get_shelters_by_id(params[:id]).to_json

  callback = params.delete('callback')
  if callback
    content_type :js
    response = "#{callback}(#{json})"
  else
    content_type :json
    response = json
  end
  response
end
