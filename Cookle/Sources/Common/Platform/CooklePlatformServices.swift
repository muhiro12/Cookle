import MHAppRuntimeCore

struct CooklePlatformServices {
    let remoteConfigurationService: RemoteConfigurationService
    let notificationService: NotificationService
    let tipController: CookleTipController
    let routePipeline: MHAppRoutePipeline<CookleRoute>
}
