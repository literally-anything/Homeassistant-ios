import Foundation
import UserNotifications
import PromiseKit

extension WebhookResponseIdentifier {
    static var serviceCall: Self { .init(rawValue: "serviceCall") }
}

struct WebhookResponseServiceCall: WebhookResponseHandler {
    let api: HomeAssistantAPI
    init(api: HomeAssistantAPI) {
        self.api = api
    }

    static func shouldReplace(request current: WebhookRequest, with proposed: WebhookRequest) -> Bool {
        // every service call is distinct
        return false
    }

    func handle(
        request: Promise<WebhookRequest>,
        result: Promise<Any>
    ) -> Guarantee<WebhookResponseHandlerResult> {
        firstly {
            when(fulfilled: request, result)
        }.get { request, _ in
            let requestDictionary = try request.asDictionary()

            let domain = requestDictionary["domain"] as? String ?? "(unknown)"
            let service = requestDictionary["service"] as? String ?? "(unknown)"
            let payload = requestDictionary["service_data"] as? [String: Any] ?? [:]

            let event = ClientEvent(
                text: "Called service: \(domain).\(service)",
                type: .serviceCall,
                payload: payload
            )

            Current.clientEventStore.addEvent(event)
        }.then { _ in
            Guarantee.value(WebhookResponseHandlerResult.default)
        }.recover { _ in
            Guarantee.value(WebhookResponseHandlerResult.default)
        }
    }
}
