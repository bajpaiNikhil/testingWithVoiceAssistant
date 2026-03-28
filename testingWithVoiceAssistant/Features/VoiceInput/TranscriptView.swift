//
//  TranscriptView.swift
//  testingWithVoiceAssistant
//
//  Created for Phase 00 — Vertical Slice
//

import SwiftUI

struct TranscriptView: View {

    @State var viewModel: TranscriptViewModel

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            transcriptArea

            Spacer()

            micButton
        }
        .padding()
    }

    // MARK: - Subviews

    private var transcriptArea: some View {
        ScrollView {
            Text(displayText)
                .font(.body)
                .foregroundStyle(textColor)
                .multilineTextAlignment(.center)
                .padding()
                .frame(maxWidth: .infinity)
                .animation(.easeIn(duration: 0.15), value: viewModel.transcript)
        }
        .frame(maxHeight: 300)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private var micButton: some View {
        Button(action: { viewModel.toggleRecording() }) {
            ZStack {
                Circle()
                    .fill(micButtonColor)
                    .frame(width: 72, height: 72)
                Image(systemName: micIconName)
                    .font(.system(size: 28))
                    .foregroundStyle(.white)
            }
        }
        .disabled(isProcessing)
        .animation(.easeInOut(duration: 0.2), value: isRecording)
    }

    // MARK: - Helpers

    private var isRecording: Bool {
        if case .recording = viewModel.state { return true }
        return false
    }

    private var isProcessing: Bool {
        if case .processing = viewModel.state { return true }
        return false
    }

    private var micButtonColor: Color {
        switch viewModel.state {
        case .recording:  return .red
        case .processing: return .gray
        default:          return .accentColor
        }
    }

    private var micIconName: String {
        switch viewModel.state {
        case .recording:  return "stop.fill"
        case .processing: return "ellipsis"
        default:          return "mic.fill"
        }
    }

    private var displayText: String {
        switch viewModel.state {
        case .idle:               return "Tap the mic to start recording"
        case .recording:          return viewModel.transcript.isEmpty ? "Listening..." : viewModel.transcript
        case .processing:         return "Transcribing..."
        case .completed:          return viewModel.transcript
        case .error(let message): return "Error: \(message)"
        }
    }

    private var textColor: Color {
        switch viewModel.state {
        case .error: return .red
        case .idle, .processing: return .secondary
        case .recording: return viewModel.transcript.isEmpty ? .secondary : .primary
        case .completed: return .primary
        }
    }
}
