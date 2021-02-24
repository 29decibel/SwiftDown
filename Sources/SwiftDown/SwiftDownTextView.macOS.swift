//
//  MdTextView.macOS.swift
//  SampleApp
//
//  Created by Quentin Eude on 01/02/2021.
//
#if os(macOS)
  import SwiftUI
  import AppKit
  import Combine
  
  private class TransparentBackgroundScroller: NSScroller {
    override func draw(_ dirtyRect: NSRect) {
        self.drawKnob()
    }
  }

  public struct SwiftDownTextView: NSViewRepresentable {
    @Binding var text: String {
      didSet {
        self.onTextChange(text)
      }
    }
    var swiftDown: SwiftDown
    var isEditable: Bool = true

    var onEditingChanged: () -> Void = {}
    var onCommit: () -> Void = {}
    var onTextChange: (String) -> Void = { _ in }

    private(set) var allowsDocumentBackgroundColorChange: Bool = true
    private(set) var backgroundColor: NSColor = .textBackgroundColor
    private(set) var color: NSColor? = nil
    private(set) var drawsBackground: Bool = true
    private(set) var font: NSFont? = .systemFont(ofSize: NSFont.systemFontSize, weight: .regular)
    private(set) var insertionPointColor: NSColor? = nil
    private(set) var textAlignment: TextAlignment = .leading
    private(set) var insetsSize: CGFloat = 0

    public init(
      text: Binding<String>,
      onEditingChanged: @escaping () -> Void = {},
      onCommit: @escaping () -> Void = {},
      onTextChange: @escaping (String) -> Void = { _ in }
    ) {
      _text = text
      self.onEditingChanged = onEditingChanged
      self.onCommit = onCommit
      self.onTextChange = onTextChange
      self.swiftDown = SwiftDown()
    }

    public func makeCoordinator() -> Coordinator {
      Coordinator(self)
    }

    public func makeNSView(context: Context) -> CustomTextView {
      let textView = CustomTextView(
        text: text,
        isEditable: isEditable,
        insetsSize: insetsSize,
        font: font
      )
      textView.delegate = context.coordinator
      updateTextViewModifiers(textView, isFirstRender: true)

      return textView
    }

    public func updateNSView(_ view: CustomTextView, context: Context) {
      view.text = text

      let formattedText =
        swiftDown
        .getFormattedText(from: text)

      updateTextViewModifiers(view, isFirstRender: false)

      view.attributedText = formattedText
      view.selectedRanges = context.coordinator.selectedRanges
    }

    private func updateTextViewModifiers(_ textView: CustomTextView, isFirstRender: Bool) {
      textView.drawsBackground = drawsBackground
      textView.allowsDocumentBackgroundColorChange = allowsDocumentBackgroundColorChange
      if isFirstRender || allowsDocumentBackgroundColorChange {
        textView.backgroundColor = backgroundColor
      }
      textView.alignment = NSTextAlignment(
        textAlignment: textAlignment,
        userInterfaceLayoutDirection: textView.userInterfaceLayoutDirection)
      textView.insertionPointColor = insertionPointColor
    }
  }

  extension SwiftDownTextView {
    public class Coordinator: NSObject, NSTextViewDelegate {
      var parent: SwiftDownTextView
      var selectedRanges: [NSValue] = []

      init(_ parent: SwiftDownTextView) {
        self.parent = parent
      }

      public func textView(
        _ textView: NSTextView, shouldChangeTextIn affectedCharRange: NSRange,
        replacementString: String?
      ) -> Bool {
        return true
      }

      public func textDidBeginEditing(_ notification: Notification) {
        guard let textView = notification.object as? NSTextView else {
          return
        }

        self.parent.text = textView.string
        self.parent.onEditingChanged()
      }

      public func textDidChange(_ notification: Notification) {
        guard let textView = notification.object as? NSTextView else {
          return
        }
        let content: String = String(textView.textStorage?.string ?? "")

        self.parent.text = content
        selectedRanges = textView.selectedRanges
      }

      public func textDidEndEditing(_ notification: Notification) {
        guard let textView = notification.object as? NSTextView else {
          return
        }

        self.parent.text = textView.string
        self.parent.onCommit()
      }
    }
  }

  public final class CustomTextView: NSView {
    private var isEditable: Bool
    private var font: NSFont?
    private var insetsSize: CGFloat

    weak var delegate: NSTextViewDelegate?

    var attributedText: NSAttributedString {
      didSet {
        textView.textStorage?.setAttributedString(attributedText)
      }
    }

    var text: String {
      didSet {
        textView.string = text
      }
    }

    var selectedRanges: [NSValue] = [] {
      didSet {
        guard selectedRanges.count > 0 else {
          return
        }

        textView.selectedRanges = selectedRanges
      }
    }

    var alignment: NSTextAlignment {
      get { textView.alignment }
      set { textView.alignment = newValue }
    }

    var allowsDocumentBackgroundColorChange: Bool {
      get { textView.allowsDocumentBackgroundColorChange }
      set { textView.allowsDocumentBackgroundColorChange = newValue }
    }

    var backgroundColor: NSColor {
      get { textView.backgroundColor }
      set { textView.backgroundColor = newValue }
    }

    var drawsBackground: Bool {
      get { textView.drawsBackground }
      set { textView.drawsBackground = newValue }
    }

    var insertionPointColor: NSColor? {
      get { textView.insertionPointColor }
      set { textView.insertionPointColor = newValue ?? textView.insertionPointColor }
    }

    private lazy var scrollView: NSScrollView = {
      let scrollView = NSScrollView()
      scrollView.drawsBackground = true
      scrollView.borderType = .noBorder
      scrollView.hasVerticalScroller = true
      scrollView.hasHorizontalRuler = false
      scrollView.autoresizingMask = [.width, .height]
      scrollView.translatesAutoresizingMaskIntoConstraints = false
      scrollView.autohidesScrollers = true
      scrollView.verticalScroller = TransparentBackgroundScroller()
      return scrollView
    }()

    private lazy var textView: NSTextView = {
      let contentSize = scrollView.contentSize
      let textStorage = NSTextStorage()

      let layoutManager = NSLayoutManager()
      textStorage.addLayoutManager(layoutManager)

      let textContainer = NSTextContainer(containerSize: scrollView.frame.size)
      textContainer.widthTracksTextView = true
      textContainer.containerSize = NSSize(
        width: contentSize.width,
        height: CGFloat.greatestFiniteMagnitude
      )

      layoutManager.addTextContainer(textContainer)

      let textView = NSTextView(frame: .zero, textContainer: textContainer)
      textView.autoresizingMask = .width
      textView.backgroundColor = NSColor.textBackgroundColor
      textView.delegate = self.delegate
      textView.drawsBackground = true
      textView.font = self.font
      textView.isEditable = self.isEditable
      textView.isHorizontallyResizable = false
      textView.isVerticallyResizable = true
      textView.maxSize = NSSize(
        width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
      textView.minSize = NSSize(width: 0, height: contentSize.height)
      textView.textColor = NSColor.labelColor
      textView.textContainerInset = NSSize(width: self.insetsSize, height: self.insetsSize)
      return textView
    }()

    // MARK: - Init
    init(text: String, isEditable: Bool, insetsSize: CGFloat, font: NSFont?) {
      self.font = font
      self.isEditable = isEditable
      self.text = text
      self.attributedText = NSMutableAttributedString()
      self.insetsSize = insetsSize
      super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Life cycle

    public override func viewWillDraw() {
      super.viewWillDraw()

      setupScrollViewConstraints()
      setupTextView()
    }

    func setupScrollViewConstraints() {
      scrollView.translatesAutoresizingMaskIntoConstraints = false

      addSubview(scrollView)

      NSLayoutConstraint.activate([
        scrollView.topAnchor.constraint(equalTo: topAnchor),
        scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
        scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
        scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
      ])
    }

    func setupTextView() {
      scrollView.documentView = textView

    }
  }

  extension SwiftDownTextView {
    public func allowsDocumentBackgroundColorChange(_ allowsChange: Bool) -> Self {
      var editor = self
      editor.allowsDocumentBackgroundColorChange = allowsChange
      return editor
    }

    public func backgroundColor(_ color: NSColor) -> Self {
      var editor = self
      editor.backgroundColor = color
      return editor
    }

    public func drawsBackground(_ shouldDraw: Bool) -> Self {
      var editor = self
      editor.drawsBackground = shouldDraw
      return editor
    }

    public func insertionPointColor(_ color: NSColor) -> Self {
      var editor = self
      editor.insertionPointColor = color
      return editor
    }

    public func multilineTextAlignment(_ alignment: TextAlignment) -> Self {
      var editor = self
      editor.textAlignment = alignment
      return editor
    }

    public func insetsSize(_ size: CGFloat) -> Self {
      var editor = self
      editor.insetsSize = size
      return editor
    }
  }
#endif
