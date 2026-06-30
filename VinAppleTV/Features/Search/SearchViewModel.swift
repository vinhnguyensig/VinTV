//
//  SearchViewModel.swift
//  VinAppleTV
//
//  Created by Vinh Nguyen on 26/6/26.
//

import Combine
import Foundation
import TVDomain

@MainActor
final class SearchViewModel: ObservableObject {
    enum State: Equatable {
        case emptyQuery
        case loading
        case results
        case noResults
        case failed(String)
    }

    @Published var query = "" {
        didSet { scheduleSearch() }
    }
    @Published private(set) var results: [Content] = []
    @Published private(set) var state: State = .emptyQuery

    private let searchContentUseCase: SearchContentUseCase
    private var searchTask: Task<Void, Never>?

    init(searchContentUseCase: SearchContentUseCase) {
        self.searchContentUseCase = searchContentUseCase
    }

    deinit {
        searchTask?.cancel()
    }

    func search(query: String) async {
        let normalizedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedQuery.isEmpty else {
            results = []
            state = .emptyQuery
            return
        }

        state = .loading

        do {
            let matches = try await searchContentUseCase.execute(query: normalizedQuery)
            guard !Task.isCancelled, self.query == query else { return }

            results = matches
            state = matches.isEmpty ? .noResults : .results
        } catch is CancellationError {
            return
        } catch {
            guard !Task.isCancelled, self.query == query else { return }
            results = []
            state = .failed(error.localizedDescription)
        }
    }

    private func scheduleSearch() {
        searchTask?.cancel()
        let currentQuery = query
        searchTask = Task { [weak self] in
            await self?.search(query: currentQuery)
        }
    }
}
