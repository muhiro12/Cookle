//
//  ContentView.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/08.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(TagContext.self) private var tagContext
    @Query private var items: [Item]

    var body: some View {
        TabView {
            NavigationSplitView {
                List {
                    ForEach(items) { item in
                        NavigationLink {
                            Text("Item at \(item.name), \(item.tag)")
                            Text("Container at \(String(describing: item.modelContext?.container.configurations.map { $0.url.pathComponents.last }))")
                        } label: {
                            Text(item.name)
                        }
                    }
                    .onDelete(perform: deleteItems)
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        EditButton()
                    }
                    ToolbarItem {
                        Button(action: addItem) {
                            Label("Add Item", systemImage: "plus")
                        }
                    }
                }
            } detail: {
                Text("Select an item")
            }
            .tabItem {
                Label("Items", systemImage: "list.bullet")
            }
            NavigationSplitView {
                List {
                    ForEach(tagContext.tags) { tag in
                        NavigationLink {
                            Text("Tag at \(tag.name)")
                        } label: {
                            Text(tag.name)
                        }
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        EditButton()
                    }
                }
            } detail: {
                Text("Select an tag")
            }
            .tabItem {
                Label("Tags", systemImage: "tag")
            }
        }
        .onAppear {
            tagContext.modify(items)
        }
    }

    private func addItem() {
        withAnimation {
            let newItem = Item(name: Date.now.description, tag: Bool.random().description)
            let newTag = Tag(name: newItem.tag)
            modelContext.insert(newItem)
            tagContext.insert(newTag)
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(items[index])
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
