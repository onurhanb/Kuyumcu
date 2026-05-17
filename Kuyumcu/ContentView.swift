//
//  ContentView.swift
//  Kuyumcu — Gold Dealer Life
//
//  Entry point preview. The real entry is MainTabView via KuyumcuApp.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        MainTabView()
    }
}

#Preview {
    ContentView().environmentObject(GameState())
}
