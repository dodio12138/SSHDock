// CommandGeneratorTests.swift
// SSHDockTests

import Testing
import Foundation
@testable import SSHDock

struct CommandGeneratorTests {

    // MARK: - 基本命令

    @Test func basicCommand() throws {
        let item = ConnectionItem(name: "Test", host: "example.com")
        let cmd = try SSHCommandGenerator.generateSSHCommand(for: item)
        #expect(cmd == "ssh example.com")
    }

    @Test func commandWithUser() throws {
        let item = ConnectionItem(name: "Test", host: "example.com", user: "ubuntu")
        let cmd = try SSHCommandGenerator.generateSSHCommand(for: item)
        #expect(cmd == "ssh ubuntu@example.com")
    }

    @Test func commandWithNonDefaultPort() throws {
        let item = ConnectionItem(name: "Test", host: "example.com", port: 2222)
        let cmd = try SSHCommandGenerator.generateSSHCommand(for: item)
        #expect(cmd == "ssh -p 2222 example.com")
    }

    @Test func commandWithKeyPath() throws {
        let item = ConnectionItem(name: "Test", host: "example.com", sshKeyPath: "~/.ssh/id_ed25519")
        let cmd = try SSHCommandGenerator.generateSSHCommand(for: item)
        // 展开 ~ 后路径被单引号包裹
        #expect(cmd.contains("-i"))
        #expect(cmd.hasSuffix("example.com"))
    }

    @Test func commandWithAllFields() throws {
        let item = ConnectionItem(
            name: "Full",
            host: "192.168.1.1",
            user: "root",
            port: 22,
            sshKeyPath: "~/.ssh/key",
            sshOptions: "-o StrictHostKeyChecking=no"
        )
        let cmd = try SSHCommandGenerator.generateSSHCommand(for: item)
        #expect(cmd.contains("root@192.168.1.1"))
        #expect(cmd.contains("-o StrictHostKeyChecking=no"))
        // port 22 不应出现 -p
        #expect(!cmd.contains("-p 22"))
    }

    // MARK: - 边界情况

    @Test func throwsOnEmptyHost() {
        let item = ConnectionItem(name: "Bad", host: "")
        #expect(throws: CommandGenerationError.emptyHost) {
            try SSHCommandGenerator.generateSSHCommand(for: item)
        }
    }

    @Test func throwsOnInvalidPort() {
        let item = ConnectionItem(name: "Bad", host: "example.com", port: 99999)
        #expect(throws: (any Error).self) {
            try SSHCommandGenerator.generateSSHCommand(for: item)
        }
    }

    @Test func shellEscapeQuotes() {
        let result = SSHCommandGenerator.shellEscape("it's a test")
        #expect(result == "'it'\\''s a test'")
    }

    // MARK: - 参数数组形式

    @Test func argumentsArray() throws {
        let item = ConnectionItem(name: "Test", host: "example.com", user: "ec2-user", port: 2222)
        let args = try SSHCommandGenerator.generateSSHArguments(for: item)
        #expect(args.contains("-p"))
        #expect(args.contains("2222"))
        #expect(args.contains("ec2-user@example.com"))
    }

    // MARK: - SCP 命令

    @Test func scpCommand() throws {
        let item = ConnectionItem(name: "Test", host: "example.com", user: "ubuntu", port: 2222)
        let cmd = try SSHCommandGenerator.generateSCPUploadCommand(
            for: item,
            localPath: "/tmp/file.txt",
            remotePath: "/home/ubuntu/file.txt"
        )
        #expect(cmd.hasPrefix("scp"))
        #expect(cmd.contains("-P 2222"))
        #expect(cmd.contains("ubuntu@example.com"))
    }
}
