import MHPlatform

struct CookleAppServices {
    let logging: CookleAppLogging
    let remoteConfigurationService: RemoteConfigurationService
    let notificationService: NotificationService
    let tipController: CookleTipController
    let routePipeline: MHAppRoutePipeline<CookleRoute>
}
