import AppKit

@MainActor
enum CompletionFeedbackPlayer {
    private static let completionSound = NSSound(named: NSSound.Name("Glass"))
        ?? NSSound(named: NSSound.Name("Pop"))

    static func playTaskCompletedSound() {
        guard let completionSound else {
            NSSound.beep()
            return
        }

        completionSound.stop()
        completionSound.currentTime = 0
        completionSound.volume = 0.45
        completionSound.play()
    }
}
