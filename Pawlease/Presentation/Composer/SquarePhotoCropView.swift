import SwiftUI
import UIKit

struct SquarePhotoCropView: View {
    let image: UIImage
    let onCancel: () -> Void
    let onUsePhoto: (Data) -> Void

    @State private var scale: CGFloat = 1
    @State private var offset = CGSize.zero
    @GestureState private var gestureScale: CGFloat = 1
    @GestureState private var gestureOffset = CGSize.zero

    private let photoProcessingService = PhotoProcessingService()

    var body: some View {
        GeometryReader { proxy in
            let cropSide = min(proxy.size.width - 32, proxy.size.height * 0.62)
            let effectiveScale = min(max(scale * gestureScale, 1), 5)
            let effectiveOffset = clampedOffset(
                CGSize(
                    width: offset.width + gestureOffset.width,
                    height: offset.height + gestureOffset.height
                ),
                scale: effectiveScale,
                cropSide: cropSide
            )

            VStack(spacing: 20) {
                Spacer(minLength: 0)

                ZStack {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: cropSide, height: cropSide)
                        .scaleEffect(effectiveScale)
                        .offset(effectiveOffset)
                }
                .frame(width: cropSide, height: cropSide)
                .clipped()
                .overlay {
                    Rectangle()
                        .stroke(.white.opacity(0.9), lineWidth: 2)
                        .allowsHitTesting(false)
                }
                .gesture(dragGesture(cropSide: cropSide, scale: effectiveScale))
                .simultaneousGesture(magnifyGesture(cropSide: cropSide))
                .accessibilityLabel("Square photo crop")
                .accessibilityHint("Drag to reposition and pinch to zoom")

                Text("Drag to reposition · Pinch to zoom")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Spacer(minLength: 0)
            }
            .padding(.bottom)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .safeAreaInset(edge: .top, spacing: 0) {
                cropHeader(cropSide: cropSide)
            }
        }
        .background(Color.black.ignoresSafeArea())
        .foregroundStyle(.white)
    }

    private func cropHeader(cropSide: CGFloat) -> some View {
        ZStack {
            Text("Crop Photo")
                .font(.headline)

            HStack {
                Button(action: onCancel) {
                    Text("Cancel")
                        .fontWeight(.semibold)
                        .padding(.horizontal, 18)
                        .frame(minHeight: 44)
                        .background(.white.opacity(0.16), in: Capsule())
                }

                Spacer()

                Button {
                    guard let data = photoProcessingService.croppedData(
                        from: image,
                        viewportSide: cropSide,
                        zoom: scale,
                        offset: offset
                    ) else { return }
                    onUsePhoto(data)
                } label: {
                    Text("Use Photo")
                        .fontWeight(.semibold)
                        .padding(.horizontal, 18)
                        .frame(minHeight: 44)
                        .background(.blue, in: Capsule())
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 56)
        .padding(.bottom, 12)
        .background(Color.black)
    }

    private func dragGesture(cropSide: CGFloat, scale: CGFloat) -> some Gesture {
        DragGesture()
            .updating($gestureOffset) { value, state, _ in
                state = value.translation
            }
            .onEnded { value in
                offset = clampedOffset(
                    CGSize(
                        width: offset.width + value.translation.width,
                        height: offset.height + value.translation.height
                    ),
                    scale: scale,
                    cropSide: cropSide
                )
            }
    }

    private func magnifyGesture(cropSide: CGFloat) -> some Gesture {
        MagnifyGesture(minimumScaleDelta: 0.01)
            .updating($gestureScale) { value, state, _ in
                state = value.magnification
            }
            .onEnded { value in
                scale = min(max(scale * value.magnification, 1), 5)
                offset = clampedOffset(offset, scale: scale, cropSide: cropSide)
            }
    }

    private func clampedOffset(_ proposed: CGSize, scale: CGFloat, cropSide: CGFloat) -> CGSize {
        guard image.size.width > 0, image.size.height > 0 else { return .zero }
        let baseScale = max(cropSide / image.size.width, cropSide / image.size.height)
        let displayedWidth = image.size.width * baseScale * scale
        let displayedHeight = image.size.height * baseScale * scale
        let maximumX = max((displayedWidth - cropSide) / 2, 0)
        let maximumY = max((displayedHeight - cropSide) / 2, 0)

        return CGSize(
            width: min(max(proposed.width, -maximumX), maximumX),
            height: min(max(proposed.height, -maximumY), maximumY)
        )
    }
}
