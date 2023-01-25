//
//  ContentView.swift
//  CovidTrackr
//
//  Created by Amron B on 1/17/23.
//

import SwiftUI

struct ContentView: View {
    
    var dashboardViewModel: DashboardViewModel = DashboardViewModel()
    
    init(){
        self.dashboardViewModel.fetchCountryData()
        self.dashboardViewModel.fetchGlobalTimeline()
    }
    var body: some View {
        TabView {
            DashboardView(viewModel: dashboardViewModel)
                .tabItem{
                    Image(systemName: "house")
                    Text("Dashboard")
                }
                
            CountryListView(viewModel: dashboardViewModel)
                .tabItem{
                    Image(systemName: "list.dash")
                    Text("Countries")
                }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
