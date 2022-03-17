import UIKit
import Foundation

extension APIScope {
    /// https://vk.com/dev/ads
    public enum Ads: APIMethod {
        case addOfficeUsers
        case checkLink
        case createAds
        case createCampaigns
        case createClients
        case createLookalikeRequest
        case createTargetGroup
        case createTargetPixel
        case deleteAds
        case deleteCampaigns
        case deleteClients
        case deleteTargetGroup
        case deleteTargetPixel
        case getAccounts
        case getAds
        case getAdsLayout
        case getAdsTargeting
        case getBudget
        case getCampaigns
        case getCategories
        case getClients
        case getDemographics
        case getFloodStats
        case getLookalikeRequests
        case getOfficeUsers
        case getPostsReach
        case getRejectionReason
        case getStatistics
        case getSuggestions
        case getTargetGroups
        case getTargetPixels
        case getTargetingStats
        case getUploadURL
        case getVideoUploadURL
        case importTargetContacts
        case removeOfficeUsers
        case saveLookalikeRequestResult
        case updateAds
        case updateCampaigns
        case updateClients
        case updateTargetGroup
        case updateTargetPixel
    }
}
