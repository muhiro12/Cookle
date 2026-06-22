import Foundation

struct DiaryFormPrefill {
    let date: Date
    let breakfasts: Set<Recipe>
    let lunches: Set<Recipe>
    let dinners: Set<Recipe>
    let note: String
}
