
extension Dictionary {
  func queryString() -> String {
    var comps = [NSURLQueryItem]()
    for (key, val) in self {
      comps.append(NSURLQueryItem(name: key as! String, value: val as! String))
    }
    let components = NSURLComponents()
    components.queryItems = comps
    return components.query!
  }
}
