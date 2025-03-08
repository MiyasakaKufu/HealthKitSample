import SwiftUI
import HealthKit
import HealthKitUI
import Observation
import OSLog

// 歩数を取得してみる
@Observable
class Model {
    let healthStore: HKHealthStore
    let quantityType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
    let calender = Calendar.current
    let logger = Logger(subsystem: "health", category: "model")

    var stepCount: Double? = 0

    init(healthStore: HKHealthStore){
        self.healthStore = healthStore
    }

    func update() async {
        let endDate = Date.now
        let startDate = calender.date(byAdding: .day, value: -1, to: endDate)
        do {
            try await save()
        } catch {
            logger.warning("failed save")
            logger.warning("\(error)")
        }
        do {
            stepCount = try await stepCountSum(startDate: startDate, endDate: endDate)
        } catch {
            logger.warning("failed update")
            logger.warning("\(error)")
        }
    }

    // FIXME: - なんか失敗する（あんまり使う機能じゃなさそう）
    func save() async throws {
        guard let savingObject = createSavingObject() else {
            logger.warning("failed save")
            return
        }
        try await healthStore.save(savingObject)
    }

    private func createSavingObject() -> HKObject? {
        let value: Double = 1.0
        let endDate = Date.now
        let startDate = calender.date(
            byAdding: .day,
            value: -1,
            to: endDate
        )

        guard let sampleType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            return nil
        }

        let quantity = HKQuantity(unit: .count(), doubleValue: value)
        let quantitySample = HKQuantitySample(
            type: sampleType,
            quantity: quantity,
            start: startDate!,
            end: endDate
        )

        return quantitySample
    }

    private func stepCountSum(
        startDate: Date?,
        endDate: Date?
    ) async throws -> Double? {
        let periodPredicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate
        )
        let predicate = HKSamplePredicate.quantitySample(
            type: quantityType,
            predicate: periodPredicate
        )
        let descriptor = HKStatisticsQueryDescriptor(
            predicate: predicate,
            options: .cumulativeSum
        )

        let sum = try await descriptor.result(for: healthStore)?
            .sumQuantity()?
            .doubleValue(for: .count())

        return sum
    }

}

struct ContentView: View {
    @State var model: Model
    @Binding var authenticated: Bool
    @State private var trigger = false

    var body: some View {
        HStack {
            Text("step count:")
            Text("\(model.stepCount ?? 0)")
        }
        .onChange(of: authenticated, { oldValue, newValue in
            Task {
                await model.update()
            }
        })
        .padding()
    }
}

#Preview {
    struct _Preview: View {
        @State var authenticated = false
        var body: some View {
            ContentView(model: .init(healthStore: .init()), authenticated: $authenticated)
        }
    }
    return _Preview()
}
