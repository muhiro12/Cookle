import MHPlatform

struct CookleAppServices {
    let configurationService: ConfigurationService
    let notificationService: NotificationService
    let tipController: CookleTipController
    let routePipeline: MHAppRoutePipeline<CookleRoute>
}
