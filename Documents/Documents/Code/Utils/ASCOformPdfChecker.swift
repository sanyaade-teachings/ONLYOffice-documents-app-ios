//
//  ASCOformPdfChecker.swift
//  Documents
//
//  Created by Alexander Yuzhin on 29.01.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

import DocumentConverter
import FileKit
import Foundation

final class ASCOformPdfChecker {
    class func check(data: Data?) -> Bool {
        data?.string(encoding: .utf8)?.contains("/ONLYOFFICEFORM") ?? false
    }

    class func checkLocal(url: URL?) -> Bool {
        guard let url, url.isFileURL else { return false }
        return DocumentLocalConverter.officeFileFormat(url) == DocumentConverter.OfficeFormatType.documentOformPdf
    }

    class func checkCloud(url: URL?, for provider: ASCFileProviderProtocol) async -> Bool {
        guard let url else { return false }

        let destination = Path.userTemporary + UUID().uuidString

        return await withCheckedContinuation { continuation in
            provider.download(url.absoluteString, to: URL(fileURLWithPath: destination.rawValue), range: 0 ..< 110) { result, progress, error in

                if error != nil {
                    continuation.resume(
                        returning: false
                    )
                    return
                }

                if let data = result as? Data, data.count > 110 {
                    continuation.resume(
                        returning: check(data: data)
                    )
                }
            }
        }
    }
}