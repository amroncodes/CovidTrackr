//
//  MapView.swift
//  CovidTrackr
//
//  Created by Amron B on 1/28/23.
//
//
//

import SwiftUI
import MapboxMaps

struct WorldMapView: UIViewControllerRepresentable {
    @State var choice: String = "Cases"
    @ObservedObject var viewModel: DashboardViewModel
    
    func makeUIViewController(context: Context) -> WorldMapViewController {
        return WorldMapViewController(viewModel: viewModel)
    }
    
    func updateUIViewController(_ uiViewController: WorldMapViewController, context: Context) {
        
    }
}

class WorldMapViewController: UIViewController {
    internal var worldMapView: MapView!
    private var viewModel: DashboardViewModel

    
    init(viewModel: DashboardViewModel){
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func viewDidLoad() {
        // Get access token from info.plist
        let accessToken = Bundle.main.object(forInfoDictionaryKey: "MBXAccessToken") as! String
        
        // Setup map options
        let resourceOptions = ResourceOptions(accessToken: accessToken)
        let mapInitOptions = MapInitOptions(
            resourceOptions: resourceOptions,
            styleURI: StyleURI(rawValue: "mapbox://styles/amroncodes/clchndkb5000515pofk3817vo")
        )
   
        // Create world map with Mapbox API
        worldMapView = MapView(frame: view.bounds, mapInitOptions: mapInitOptions)
        worldMapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        // Pass map to WorldMapView
        self.view.addSubview(worldMapView)
        
        // Run the following when the base map loads
        worldMapView.mapboxMap.onNext(event: .mapLoaded) { _ in
            self.addTileDataLayer()
        }
    }
    
    
    // Create a data layer (Choropleth) using the Mapbox Countries tileset
    func addTileDataLayer() {
        // Sample Data
        struct Country {
            let code: String
            let cases: Int
            let deaths: Int
        }
        let max_cases = 10000000 // Todo: Find max

        // Create the source for country polygons using the Mapbox Countries tileset
        // The polygons contain an ISO 3166 alpha-3 code which can be used to for joining the data
        // https://docs.mapbox.com/vector-tiles/reference/mapbox-countries-v1
        let sourceID = "countries"
        var source = VectorSource()
        source.url = "mapbox://mapbox.country-boundaries-v1"
        
        // Add layer from the vector tile source to create the choropleth
        var layer = FillLayer(id: "countries")
        layer.source = sourceID
        layer.sourceLayer = "country_boundaries"
        
        // Build a GL match expression that defines the color for every vector tile feature
        // https://docs.mapbox.com/mapbox-gl-js/style-spec/expressions/#match
        // Use the ISO 3166-1 alpha 3 code as the lookup key for the country shape
        let expressionHeader =
            """
            [
            "match",
            ["get", "iso_3166_1_alpha_3"],

            """

        // Calculate color values for each country based on 'cases' value
        var colorValue: Double
        var expressionBody: String = ""
        
        // Convert the range of data values (countries) to a suitable color
        for country in viewModel.countries {
            // Calculate percentage of max cases
            let ratio = Double(country.stats!.confirmed)/Double(max_cases) * 255 + 20
            
            // Set color value based on the ratio of cases
            colorValue = (ratio > 255) ? 255 : ratio // red
            
            // Extract iso3 of the country to build expression body
            if let iso3 = country.info?.iso3 {
                expressionBody += """
                "\(iso3)",
                "rgb(255, \(255 - colorValue), \(255 - colorValue))",

                """
            }

        }

        // Last value is the default, used where there is no data
        let expressionFooter =
            """
            "rgba(0, 0, 0, 0)"
            ]
            """

        // Combine the expression strings into a single JSON expression
        // You can alternatively translate JSON expressions into Swift: https://docs.mapbox.com/ios/maps/guides/styles/use-expressions/
        let jsonExpression = expressionHeader + expressionBody + expressionFooter

        // Add the source
        // Insert the vector layer below the 'admin-1-boundary-bg' layer in the style
        // Join data to the vector layer
        do {
            try worldMapView.mapboxMap.style.addSource(source, id: sourceID)
            try worldMapView.mapboxMap.style.addLayer(layer, layerPosition: .below("admin-1-boundary-bg"))
            if let expressionData = jsonExpression.data(using: .utf8) {
                let expJSONObject = try JSONSerialization.jsonObject(with: expressionData, options: [])
                try worldMapView.mapboxMap.style.setLayerProperty(
                    for: "countries",
                    property: "fill-color",
                    value: expJSONObject
                )
            }
        } catch {
            print("Failed to add the data layer. Error: \(error.localizedDescription)")
        }
    }
}

