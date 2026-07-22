import SwiftUI

struct CopyableLink<Content: View>: View {
  let destination: URL
  let copyAction: () -> Void
  let label: Content

  init(
    destination: URL,
    copyAction: @escaping () -> Void,
    @ViewBuilder label: () -> Content
  ) {
    self.destination = destination
    self.copyAction = copyAction
    self.label = label()
  }

  var body: some View {
    link
      .contextMenu {
        Button(action: performCopy) {
          Label(
            String(localized: "拷貝", bundle: .module),
            systemImage: "document.on.document"
          )
        }
      }
  }

  var link: Link<Content> {
    Link(destination: destination) {
      label
    }
  }

  func performCopy() {
    copyAction()
  }
}
