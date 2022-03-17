import UIKit
import Foundation

extension APIScope {
    /// https://vk.com/dev/database
    public enum Database: APIMethod {
        case getChairs
        case getCities
        case getCitiesById
        case getCountries
        case getCountriesById
        case getFaculties
        case getRegions
        case getSchoolClasses
        case getSchools
        case getStreetsById
        case getUniversities
    }
}
