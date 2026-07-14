enum CookleDataArchiveResourceCategory: String, Sendable {
    case encodedData = "encoded backup data"
    case ingredientRecords = "ingredient records"
    case categoryRecords = "category records"
    case photoRecords = "photo records"
    case recipeRecords = "recipe records"
    case diaryRecords = "diary records"
    case nestedRecords = "nested records"
    case identifier = "identifier text"
    case text = "text content"
    case photoData = "individual photo data"
    case aggregatePhotoData = "total photo data"
}
