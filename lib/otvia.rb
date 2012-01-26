# encoding: utf-8
require 'rubygems'
require 'open-uri'
require 'v8'
require 'yajl'
require 'nokogiri'

def get_vehicles_raw
  # Lets get the data from OTVia
  str = open('http://getonboard.lincoln.ne.gov/packet/json/vehicle?routes=203,204,205,206,207,208,209,210,211,212,213,214,215,216,217,218,219&lastVehicleHttpRequestTime=1').read

  # OTVia gives us Javascript literals, we need a javascript parser!
  ctx = V8::Context.new

  # We could walk the JS object in ruby and parse it, but that's slow.
  # Returning one big string and re-parsing it is way faster.
  json_string = ctx.eval('JSON.stringify(' + str + ')')

  # Now we actually make a native ruby object
  parser = Yajl::Parser.new
  nice_json = parser.parse(json_string)

  # ...do stuff with nice_json...
  return nice_json
end

def get_shelters_raw
  # Lets get the data from OTVia
  str = open('http://getonboard.lincoln.ne.gov/packet/json/shelter?routes=204,205,206,207,208,209,210,211,212,213,214,215,216,217,218,219,220,221&lastShelterHttpRequestTime=0').read

  # OTVia gives us Javascript literals, we need a javascript parser!
  ctx = V8::Context.new

  # We could walk the JS object in ruby and parse it, but that's slow.
  # Returning one big string and re-parsing it is way faster.
  json_string = ctx.eval('JSON.stringify(' + str + ')')

  # Now we actually make a native ruby object
  parser = Yajl::Parser.new
  nice_json = parser.parse(json_string)

  # ...do stuff with nice_json...
  return nice_json
end

def parse_vehicles(data)

  vehicles = data["VehicleArray"]
  results = Array.new

  vehicles.each do |tmpVehicle|
    vehicle = Hash.new
    tmpVehicle = tmpVehicle["vehicle"]
    vehicle["id"] = tmpVehicle["id"]
    vehicle["route_id"] = tmpVehicle["routeID"].to_s
    frag = Nokogiri::HTML::fragment(tmpVehicle["WebLabel"])
    vehicle["predictions"] = Hash.new
    vehicle["predictions"]["arrivalTime0"] = tmpVehicle["PredictionTimes"].values[0].to_s[0..-4].to_i
    vehicle["predictions"]["arrivalTime1"] = tmpVehicle["PredictionTimes"].values[0].to_s[0..-4].to_i
    vehicle["location"] = Hash.new
    vehicle["location"]["latitude"] = (tmpVehicle["CVLocation"]["latitude"].to_f/100000)
    vehicle["location"]["longitude"] = (tmpVehicle["CVLocation"]["longitude"].to_f/100000)
    vehicle["location"]["direction"] = tmpVehicle["CVLocation"]["angle"]
    vehicle["location"]["updatedAt"] = tmpVehicle["CVLocation"]["locTime"]
    vehicle["location"]["speed"] = tmpVehicle["CVLocation"]["speed"]

    vehicle["name"] = frag.css('.labelVehicleHeader').text.strip
    vehicle["next_stop"] = Hash.new
    if(frag.css('.labelVehicleCurrentRow')[0].nil? || ("Current Stop  N/A" == frag.css('.labelVehicleCurrentRow')[0].text.split("Next Stop  ").last.split("-").first.strip))
      vehicle["next_stop"]["name"] = "N/A"
      vehicle["next_stop"]["eta"] = "N/A"
    else
      vehicle["next_stop"]["name"] = frag.css('.labelVehicleCurrentRow')[0].text.split("Next Stop  ").last.split("-").first.strip
      vehicle["next_stop"]["eta"] = frag.css('.labelVehicleCurrentRow')[1].text.split("ETA   ").last.strip
    end
    vehicle["upcoming_stop"] = Hash.new
    if(frag.css('.labelVehicleNextRow')[0].nil?)
      vehicle["upcoming_stop"]["name"] = "N/A"
      vehicle["upcoming_stop"]["eta"] = "N/A"
    else
      vehicle["upcoming_stop"]["name"] = frag.css('.labelVehicleNextRow')[0].text.split("Next Stop  ").last.split("-").first.strip
      vehicle["upcoming_stop"]["eta"] = frag.css('.labelVehicleNextRow')[1].text.split("ETA   ").last.strip
    end
    results.push vehicle
  end

  return results
end

def parse_shelters(data)
  shelters = data["ShelterArray"]
  if(shelters.length == 0)
    return nil
  end
  results = Array.new
  shelters.each do |tmpShelter|
    shelter = Hash.new
    tmpShelter = tmpShelter["Shelter"]
    shelter["route_ids"] = tmpShelter["routeIDs"]
    shelter["id"] = tmpShelter["ShelterId"].to_s
    shelter["name"] = tmpShelter["ShelterName"]
    shelter["location"] = Hash.new
    shelter["location"]["latitude"] = tmpShelter["Latitude"].to_f/100000
    shelter["location"]["longitude"] = tmpShelter["Longitude"].to_f/100000
    shelter["arrival_times"] = parse_shelter_times(Nokogiri::HTML::fragment(tmpShelter["WebLabel"])) 
    results.push shelter
  end

  return results
end

def parse_shelter_times(n)
  route = ""
  times = Hash.new

  n.css("div.labelShelterRouteListing div").each do |div|
    if(div.attr('class') == "labelShelterHeaderRouteRow")
      route = div.children[1].children.attr('onclick').text.split("route=").last.split("&").first
      next
    elsif(div.attr('class') == "labelShelterArrivalRowOdd" || div.attr('class') == "labelShelterArrivalRowEven")
      time = div.text.split('Arrival').last.gsub(/\P{ASCII}/, '').strip
      if(route == "")
        next
      end
      if(!times.has_key? route)
        times[route] = Array.new
      end
      times[route].push time
      next
    end
  end
  return times
end
def get_vehicles_by_id(id = "0")
  vehicles = parse_vehicles get_vehicles_raw

  if(id == "0")
    return vehicles
  end

  vehicles.each do |vehicle|
    if(vehicle["id"] = id)
      return vehicle
    end
  end

  return nil
end

def get_vehicles_by_route(route = "0")
  vehicles = parse_vehicles get_vehicles_raw

  routes = Hash.new
  vehicles.each do |vehicle|
    if(routes.has_key? vehicle["route_id"])
      routes[vehicle["route_id"]].push vehicle
    else
      routes[vehicle["route_id"]] = Array.new
      routes[vehicle["route_id"]].push vehicle
    end
  end

  if(route != "0")
    if(routes.has_key? route)
      routes = routes[route]
    else
      routes = nil
    end
  end

  return routes
end

def get_shelters_by_id(id = "0")
  shelters = parse_shelters get_shelters_raw

  if(id == "0")
    return shelters
  end

  shelters.each do |shelter|
    if(shelter["id"] = id)
      return shelter
    end
  end

  return nil
end
