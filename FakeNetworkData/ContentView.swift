//
//  ContentView.swift
//  FakeNetworkData
//
//  Created by David Okun on 5/25/23.
//

import SwiftUI

protocol NetworkSession {
  func getData(from url: URL) async throws -> Data
}

enum MockSessionError: Error {
  case badPath
  case badURL
  case badData
}

extension URLSession: NetworkSession {
  func getData(from url: URL) async throws -> Data {
    do {
      let (data, _) = try await URLSession.shared.data(from: url)
      return data
    } catch {
      throw error
    }
  }
}

struct MockSession: NetworkSession {
  func getData(from url: URL) async throws -> Data {
    guard let filePath = Bundle.main.path(forResource: "FakeResponse", ofType: "json") else {
      throw MockSessionError.badPath
    }
    let fileURL = URL(filePath: filePath)
    do {
      let data = try Data(contentsOf: fileURL, options: .mappedIfSafe)
      return data
    } catch {
      print(error.localizedDescription)
      throw MockSessionError.badData
    }
  }
}

struct APIResponse: Codable {
  var title: String
}

struct ContentView: View {
  func makeRequest(useRealNetwork: Bool = true) async {
    var session: NetworkSession = URLSession.shared
    if !useRealNetwork {
      session = MockSession()
    }
    guard let url = URL(string: "https://jsonplaceholder.typicode.com/todos/1") else {
      response = "error"
      return
    }
    do {
      let data = try await session.getData(from: url)
      let dataResponse = try JSONDecoder().decode(APIResponse.self, from: data)
      response = dataResponse.title
    } catch {
      print(error.localizedDescription)
    }
  }
  
  @State var useFakeNetwork = false
  @State var isLoading = false
  @State var response: String? = nil
  
  var body: some View {
    VStack {
      Toggle(isOn: $useFakeNetwork) {
        Text(useFakeNetwork ? "Real Network" : "Fake Network")
      }
      .padding()
      Button {
        Task {
          isLoading = true
          await makeRequest(useRealNetwork: useFakeNetwork)
          isLoading = false
        }
      } label: {
        Text(isLoading ? "Loading data..." : "Make GET Request")
      }.disabled(isLoading)
      if let response {
        Text(response).padding()
      }
    }
    .padding()
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
