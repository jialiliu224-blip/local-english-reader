struct PresentationPolicy {
 static func showEditor(background:Bool)->Bool { !background }
 static func showResult(speechDone:Bool,hasResult:Bool)->Bool { speechDone && hasResult }
}
