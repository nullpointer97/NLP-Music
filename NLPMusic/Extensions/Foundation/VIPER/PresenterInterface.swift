protocol PresenterInterface: AnyObject {
    var isPageNeed: Bool { get set }
    func onEndRefreshing()
    func onDidFinishLoad()
    func onError(message: String)
}

extension PresenterInterface {
}
