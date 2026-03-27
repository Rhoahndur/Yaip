import XCTest
@testable import Yaip

@MainActor
final class UserSearchViewModelTests: XCTestCase {

    private var viewModel: UserSearchViewModel!
    private var mockUserService: MockUserService!
    private var mockAuthManager: MockAuthManager!

    override func setUp() {
        super.setUp()
        mockUserService = MockUserService()
        mockAuthManager = MockAuthManager()
        mockAuthManager.currentUserID = "currentUser"

        // Populate mock users
        mockUserService.users = [
            "currentUser": TestFixtures.user(id: "currentUser", displayName: "Current User"),
            "user2": TestFixtures.user(id: "user2", displayName: "Alice Smith", email: "alice@example.com"),
            "user3": TestFixtures.user(id: "user3", displayName: "Bob Jones", email: "bob@example.com"),
            "user4": TestFixtures.user(id: "user4", displayName: "Alice Wonder", email: "alice.w@example.com")
        ]

        viewModel = UserSearchViewModel(
            userService: mockUserService,
            authManager: mockAuthManager
        )
    }

    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }

    // MARK: - Initial State

    func testInitialState() {
        XCTAssertTrue(viewModel.users.isEmpty)
        XCTAssertEqual(viewModel.searchText, "")
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }

    // MARK: - Fetch All Users

    func testFetchAllUsersExcludesCurrentUser() async {
        await viewModel.fetchAllUsers()

        XCTAssertEqual(viewModel.users.count, 3)
        XCTAssertFalse(viewModel.users.contains { $0.id == "currentUser" })
    }

    func testFetchAllUsersSetsLoadingFalse() async {
        await viewModel.fetchAllUsers()

        XCTAssertFalse(viewModel.isLoading)
    }

    func testFetchAllUsersHandlesError() async {
        mockUserService.shouldFail = true
        await viewModel.fetchAllUsers()

        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isLoading)
    }

    // MARK: - Search Users

    func testSearchUsersFiltersResults() async {
        await viewModel.searchUsers(query: "Alice")

        XCTAssertEqual(viewModel.users.count, 2)
        XCTAssertTrue(viewModel.users.allSatisfy { $0.displayName.contains("Alice") })
    }

    func testSearchUsersExcludesCurrentUser() async {
        await viewModel.searchUsers(query: "Current")

        XCTAssertFalse(viewModel.users.contains { $0.id == "currentUser" })
    }

    func testSearchWithEmptyQueryFetchesAll() async {
        await viewModel.searchUsers(query: "")

        XCTAssertEqual(viewModel.users.count, 3)
    }

    func testSearchUsersHandlesError() async {
        mockUserService.shouldFail = true
        await viewModel.searchUsers(query: "Alice")

        XCTAssertNotNil(viewModel.errorMessage)
    }

    func testSearchUsersSetsLoadingFalse() async {
        await viewModel.searchUsers(query: "Alice")

        XCTAssertFalse(viewModel.isLoading)
    }

    // MARK: - No Auth

    func testFetchAllUsersWithNoAuthReturnsAll() async {
        mockAuthManager.currentUserID = nil
        await viewModel.fetchAllUsers()

        XCTAssertEqual(viewModel.users.count, 4)
    }
}
