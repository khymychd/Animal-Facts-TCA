//

import Foundation

enum APIModel {
    
    struct Categorie: Decodable {
        
        enum Status {
            case free
            case premium
            case comingSoon
        }
        
        struct Content: Decodable {
            let fact: String
            let image: String
        }
        
        let order: Int
        let title: String
        let description: String
        let imageURL: String
        let status: Status
        let content: [Content]?
        
        enum CodingKeys: String, CodingKey {
            case order = "order"
            case title = "title"
            case description = "description"
            case imageURL = "image"
            case status = "status"
            case content = "content"
        }
        
        init(
            order: Int,
            title: String,
            description: String,
            imageURL: String,
            status: Status,
            content: [Content]?
        ) {
            self.order = order
            self.title = title
            self.description = description
            self.imageURL = imageURL
            self.status = status
            self.content = content
        }
        
        init(from decoder: any Decoder) throws {
            let container: KeyedDecodingContainer<CodingKeys> = try decoder.container(keyedBy: CodingKeys.self)
            self.order = try container.decode(Int.self, forKey: .order)
            self.title = try container.decode(String.self, forKey: .title)
            self.description = try container.decode(String.self, forKey: .description)
            self.imageURL = try container.decode(String.self, forKey: .imageURL)
            let content = try container.decodeIfPresent([Content].self, forKey: .content)
            self.content = content
            guard let content, !content.isEmpty else {
                self.status = .comingSoon
                return
            }
            let status = try container.decode(String.self, forKey: .status)
            switch status {
            case "free":
                self.status = .free
            case "paid":
                self.status = .premium
            default:
                assertionFailure("Unhandled case")
                self.status = .comingSoon
            }
        }
    }
}

// MARK: - Categories Stub
extension [APIModel.Categorie] {
    
    static var stub: Self = (0..<4).map {
        .init(
            order: $0,
            title: "Title \($0)",
            description: "Description \($0)",
            imageURL: "\($0)",
            status: $0 == 0 ? .free : $0 == 1 ? .premium : .comingSoon,
            content: $0 == 0 ? .stub : $0 == 1 ? nil : .stub
        )
    }
}

// MARK: - Categories Content Stup
extension [APIModel.Categorie.Content] {
    
    static var stub: Self = (0..<10).map {
        .init(fact: "Fact at number \($0)", image: "\($0)")
    }
}
