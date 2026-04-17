// ModelTests.swift
// SSHDockTests

import Testing
import Foundation
import SwiftData
@testable import SSHDock

@MainActor
struct ModelTests {

    // 每个测试用 in-memory container，互相隔离
    private func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: ConnectionItem.self, configurations: config)
    }

    @Test func insertAndFetch() throws {
        let container = try makeContainer()
        let ctx = container.mainContext

        let item = ConnectionItem(name: "My Server", host: "10.0.0.1", user: "admin")
        ctx.insert(item)
        try ctx.save()

        let fetched = try ctx.fetch(FetchDescriptor<ConnectionItem>())
        #expect(fetched.count == 1)
        #expect(fetched.first?.name == "My Server")
        #expect(fetched.first?.host == "10.0.0.1")
    }

    @Test func updateFields() throws {
        let container = try makeContainer()
        let ctx = container.mainContext

        let item = ConnectionItem(name: "Old", host: "old.host")
        ctx.insert(item)
        try ctx.save()

        item.name = "New"
        item.host = "new.host"
        item.port = 2222
        try ctx.save()

        let fetched = try ctx.fetch(FetchDescriptor<ConnectionItem>())
        #expect(fetched.first?.name == "New")
        #expect(fetched.first?.port == 2222)
    }

    @Test func deleteItem() throws {
        let container = try makeContainer()
        let ctx = container.mainContext

        let item = ConnectionItem(name: "ToDelete", host: "x.com")
        ctx.insert(item)
        try ctx.save()

        ctx.delete(item)
        try ctx.save()

        let fetched = try ctx.fetch(FetchDescriptor<ConnectionItem>())
        #expect(fetched.isEmpty)
    }

    @Test func tagsAndFavorite() throws {
        let container = try makeContainer()
        let ctx = container.mainContext

        let item = ConnectionItem(name: "Tagged", host: "t.com", tags: ["prod", "web"], isFavorite: true)
        ctx.insert(item)
        try ctx.save()

        let fetched = try ctx.fetch(FetchDescriptor<ConnectionItem>()).first
        #expect(fetched?.tags.contains("prod") == true)
        #expect(fetched?.isFavorite == true)
    }

    @Test func lastUsedAtUpdates() throws {
        let container = try makeContainer()
        let ctx = container.mainContext

        let item = ConnectionItem(name: "Usable", host: "u.com")
        ctx.insert(item)
        try ctx.save()

        #expect(item.lastUsedAt == nil)

        let now = Date()
        item.lastUsedAt = now
        try ctx.save()

        let fetched = try ctx.fetch(FetchDescriptor<ConnectionItem>()).first
        #expect(fetched?.lastUsedAt != nil)
    }
}
