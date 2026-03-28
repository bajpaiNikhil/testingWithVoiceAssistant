//
//  ContentView.swift
//  testingWithVoiceAssistant
//
//  Created by Nikhil Bajpai on 22/03/26.
//

import SwiftUI

struct ContentView: View {

    @State private var viewModel: TranscriptViewModel

    init(engine: WhisperEngine) {
        _viewModel = State(wrappedValue: TranscriptViewModel(engine: engine))
    }

    var body: some View {
        TranscriptView(viewModel: viewModel)
    }
}

