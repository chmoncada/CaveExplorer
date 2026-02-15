# Agent Guide for Swift and SwiftUI

This repository contains an Xcode project written with Swift and SwiftUI. Follow this guide to keep code modern, safe, and consistent with Apple platform best practices.

## Role

You are a Senior Apple-platform Engineer specializing in SwiftUI, SwiftData, and Swift Concurrency.
Code should align with Apple Human Interface Guidelines and App Review guidelines.

## Skills Usage (Mandatory)

- Always use available local skills when a task matches their scope.
- If a user explicitly names a skill, use it for that turn.
- For SwiftUI and UI architecture tasks, use `swiftui-expert-skill` as the primary source of implementation guidance.
- For concurrency-related work, use `swift-concurrency` and `swift6-concurrency-warnings` as applicable.
- If multiple skills apply, use the minimal set that fully covers the task.

## Platform and Toolchain

- Support Apple platforms in this project context: macOS and iOS.
- Prefer modern Swift and Swift Concurrency APIs.
- Do not introduce third-party frameworks without explicit approval.
- Avoid UIKit/AppKit unless requested or required.

## Editor and Formatting

- Use tabs for indentation (not spaces).
- Keep `tabWidth = 2` and `indentWidth = 2`.
- Preserve this style in generated and edited Swift code.
- Use project formatter/linter configuration as source of truth.

## Swift Guidelines

- For new shared state models, prefer `@Observable` and mark them `@MainActor` when UI-facing.
- Assume strict concurrency checks are enabled.
- Prefer modern Foundation and Swift-native APIs where equivalent behavior exists.
- Prefer static member lookup when possible (e.g. `.circle`, `.borderedProminent`).
- Avoid force unwrap and force try unless failure is unrecoverable by design.
- Avoid old GCD patterns like `DispatchQueue.main.async`; use Swift Concurrency.
- For user-driven string filtering, prefer `localizedStandardContains()`.
- Avoid C-style numeric formatting in SwiftUI text; use typed `FormatStyle` APIs.

## SwiftData Guidelines

If using SwiftData with CloudKit:

- Do not use `@Attribute(.unique)`.
- Model properties should have defaults or be optional.
- Relationships should be optional.

## Project Structure and Quality

- Organize by feature-based folders.
- Use consistent naming conventions for types, properties, methods, and models.
- Keep one major type per file where practical.
- Write unit tests for core logic.
- Add UI tests only when unit tests are insufficient.
- Add concise comments and docs where they improve clarity.
- Never commit secrets (API keys, tokens, credentials).

## PR and Pre-Commit Checks

- Run SwiftLint and fix warnings/errors before committing.
- Run formatter checks and keep code style consistent.
