import Testing
import Foundation
import UniformTypeIdentifiers
@testable import Pawlease

struct ShareAttachmentValidationTests {
    @Test
    func missingAttachmentReturnsADomainError() {
        switch ShareAttachmentValidation.validateImageProvider(nil) {
        case .failure(.missingAttachment):
            break
        default:
            Issue.record("Expected .missingAttachment for a nil item provider")
        }
    }

    @Test
    func unsupportedAttachmentTypeReturnsADomainError() {
        let provider = NSItemProvider(item: NSString("hello") as NSSecureCoding, typeIdentifier: UTType.plainText.identifier)

        switch ShareAttachmentValidation.validateImageProvider(provider) {
        case .failure(.unsupportedType):
            break
        default:
            Issue.record("Expected .unsupportedType for a plain-text attachment")
        }
    }

    @Test
    func anImageAttachmentPassesValidation() {
        let provider = NSItemProvider(item: NSData() as NSSecureCoding, typeIdentifier: UTType.jpeg.identifier)

        switch ShareAttachmentValidation.validateImageProvider(provider) {
        case .success:
            break
        case .failure:
            Issue.record("Expected success for a JPEG attachment")
        }
    }
}
