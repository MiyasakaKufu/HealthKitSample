import SwiftUI
import HealthKitUI
import OSLog

@main
struct HealthKitSampleApp: App {
    @State private var authenticated = false
    @State private var trigger = false

    let logger = Logger(
        subsystem: "health",
        category: "app"
    )

    let store = HKHealthStore()

    var body: some Scene {
        WindowGroup {
            ContentView(model: .init(healthStore: store), authenticated: $authenticated)
                .healthDataAccessRequest(
                    store: store,
                    readTypes: [
                        HKQuantityType(.stepCount)
                    ],
                    trigger: trigger,
                    completion: { result in
                        switch result {
                        case .success(_):
                            authenticated = true
                        case .failure(let error):
                            // Handle the error here.
                            fatalError("*** An error occurred while requesting authentication: \(error) ***")
                        }
                        logger.debug("Authentication Complete.")
                    }
                )
                .onAppear() {
                    trigger.toggle()
                }
        }
    }
}
