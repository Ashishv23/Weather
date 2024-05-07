//
//  ViewController.swift
//  Weather
//
//  Created by user237383 on 4/3/24.
//

import UIKit
import CoreLocation

//Geolocation Response Model
struct WeatherData: Codable {
    let coord: Coord
    let weather: [Weather]
    let base: String
    let main: Main
    let visibility: Int
    let wind: Wind
    let clouds: Clouds
    let dt: Int
    let sys: Sys
    let timezone: Int
    let id: Int
    let name: String
    let cod: Int
}

struct Coord: Codable {
    let lon, lat: Double
}

struct Weather: Codable {
    let id: Int
    let main, description, icon: String
}

struct Main: Codable {
    let temp: Double
    let feelsLike: Double?
    let tempMin: Double?
    let tempMax: Double?
    let pressure: Int
    let humidity: Int
    
    enum CodingKeys: String, CodingKey {
        case temp, feelsLike = "feels_like", tempMin = "temp_min", tempMax = "temp_max", pressure, humidity
    }
}

struct Wind: Codable {
    let speed, deg: Double
    let gust: Double?
}

struct Clouds: Codable {
    let all: Int
}

struct Sys: Codable {
    let type, id: Int
    let country: String
    let sunrise, sunset: Int
}

class ViewController: UIViewController, CLLocationManagerDelegate {
    
    @IBOutlet weak var cityName: UILabel!
    
    @IBOutlet weak var weatherData: UILabel!
    
    @IBOutlet weak var weatherImageData: UIImageView!
    
    @IBOutlet weak var tempratureData: UILabel!
    
    @IBOutlet weak var humidityData: UILabel!
    
    @IBOutlet weak var windData: UILabel!
    
    let locationManager = CLLocationManager()
    
    var cityNam : String = ""
    
    var latit : Double = 0.0
    
    var longi : Double = 0.0
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Request location permission
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            return
        }
        
        let latitude = location.coordinate.latitude
        let longitude = location.coordinate.longitude
        latit = latitude
        longi = longitude
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { (placemarks, error) in
            if let error = error {
                print("Geocoding error: \(error.localizedDescription)")
                return
            }
            
            //Get the city name from latitute and longitute
            if let placemark = placemarks?.first, let cityName = placemark.locality {
                self.cityNam = cityName
            }
        }
        
       fetchLocationData()
    }
    
    func fetchLocationData() {
        //Api call
        //api key
        var apiKey = "98835f2325ce4396009dd2ce7eb66b57"
//        let urlString = "https://api.openweathermap.org/data/2.5/weather?q=Waterloo,CA&appid=\(apiKey)"
        
        let urlString = "https://api.openweathermap.org/data/2.5/weather?lat=\(latit)&lon=\(longi)&appid=\(apiKey)"
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            return
        }
        
        let urlSession = URLSession(configuration: .default)
        let dataTask = urlSession.dataTask(with: url) { (data, response, error) in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error: \(error.localizedDescription)")
                    return
                }
                
                //Getting JSON from api response data
                if let data = data {
                    do {
                        let jsonData = try JSONDecoder().decode(WeatherData.self, from: data)
                        
                        DispatchQueue.main.async {
                            //Set the label values
                            self.humidityData.text = " \(jsonData.main.humidity)%"
                            self.windData.text = " \(jsonData.wind.speed) km/h"
                            
                            //Converst into C
                            let temperatureInCelsius = Int(jsonData.main.temp - 273.15)
                            
                            self.tempratureData.text = " \(temperatureInCelsius) °C"
                            
                            //Getting city name from json
                            self.cityName.text = " \(jsonData.name)"
                            
                            //Getting weather status from json
                            self.weatherData.text = "\(jsonData.weather[0].main)"
                            
                            //Weather icon set from json
                            if let iconCode = jsonData.weather.first?.icon {
                                let imageUrlString = "https://openweathermap.org/img/wn/\(iconCode).png"
                                if let imageUrl = URL(string: imageUrlString) {
                                    URLSession.shared.dataTask(with: imageUrl) { data, response, error in
                                        if let error = error {
                                            print("Error loading image: \(error.localizedDescription)")
                                            return
                                        }
                                        
                                        //Set the image in image view
                                        if let imageData = data, let image = UIImage(data: imageData) {
                                            DispatchQueue.main.async {
                                                self.weatherImageData.image = image
                                            }
                                        }
                                    
                                    }.resume()
                                } else {
                                    print("Invalid image URL: \(imageUrlString)")
                                    
                                }
                            }
                        }
                    } catch let decodingError {
                        //Error on decoed JSON
                        print("Error decoding JSON: \(decodingError)")
                        self.cityName.text = "City Not Found"
                    }
                }
            }
        }
        
        dataTask.resume()
    }
}


