protocol ViewInterface: AnyObject {
    var audioItems: [AudioPlayerItem] { get set }
    func startRefreshing()
    func endRefreshing()
    func didFinishLoad()
    func error(message: String)
}

extension ViewInterface {
}
