extension BookmarksListSortingType {
  init(_ sortingType: BookmarksSortingType) {
    switch sortingType {
    case .byType:
      self = .type
    case .byDistance:
      self = .distance
    case .byTime:
      self = .date
    case .byName:
      self = .name
    @unknown default:
      fatalError()
    }
  }
}

final class BookmarksListInteractor {
  private let markGroupId: MWMMarkGroupID
  private var bookmarksManager: BookmarksManager { BookmarksManager.shared() }

  init(markGroupId: MWMMarkGroupID) {
    self.markGroupId = markGroupId
  }
}

extension BookmarksListInteractor: IBookmarksListInteractor {
  func getBookmarkGroup() -> BookmarkGroup {
    bookmarksManager.category(withId: markGroupId)
  }

  func hasDescription() -> Bool {
    bookmarksManager.hasExtraInfo(markGroupId)
  }

  func prepareForSearch() {
    bookmarksManager.prepare(forSearch: markGroupId)
  }

  func search(_ text: String, completion: @escaping ([Bookmark]) -> Void) {
    bookmarksManager.searchBookmarksGroup(markGroupId, text: text) {
      completion($0)
    }
  }

  func availableSortingTypes(hasMyPosition: Bool) -> [BookmarksListSortingType] {
    bookmarksManager.availableSortingTypes(markGroupId, hasMyPosition: hasMyPosition).map {
      BookmarksSortingType(rawValue: $0.intValue)!
    }.map {
      switch $0 {
      case .byType:
        return BookmarksListSortingType.type
      case .byDistance:
        return BookmarksListSortingType.distance
      case .byTime:
        return BookmarksListSortingType.date
      case .byName:
        return BookmarksListSortingType.name
      @unknown default:
        fatalError()
      }
    }
  }

  func viewOnMap() {
    FrameworkHelper.show(onMap: markGroupId)
  }

  func viewBookmarkOnMap(_ bookmarkId: MWMMarkID) {
    FrameworkHelper.showBookmark(bookmarkId)
  }

  func viewTrackOnMap(_ trackId: MWMTrackID) {
    FrameworkHelper.showTrack(trackId)
  }

  func setGroup(_ groupId: MWMMarkGroupID, visible: Bool) {
    bookmarksManager.setCategory(groupId, isVisible: visible)
  }
  
  func sort(_ sortingType: BookmarksListSortingType,
            location: CLLocation?,
            completion: @escaping ([BookmarksSection]) -> Void) {
    let coreSortingType: BookmarksSortingType
    switch sortingType {
    case .distance:
      coreSortingType = .byDistance
    case .date:
      coreSortingType = .byTime
    case .type:
      coreSortingType = .byType
    case .name:
      coreSortingType = .byName
    }

    bookmarksManager.sortBookmarks(markGroupId,
                                   sortingType: coreSortingType,
                                   location: location) { sections in
      guard let sections = sections else { return }
      completion(sections)
    }
  }

  func resetSort() {
    bookmarksManager.resetLastSortingType(markGroupId)
  }

  func lastSortingType() -> BookmarksListSortingType? {
    guard bookmarksManager.hasLastSortingType(markGroupId) else {
      return nil
    }
    return BookmarksListSortingType(bookmarksManager.lastSortingType(markGroupId))
  }

  func deleteBookmark(_ bookmarkId: MWMMarkID) {
    bookmarksManager.deleteBookmark(bookmarkId)
  }

  func deleteTrack(_ trackId: MWMTrackID) {
    bookmarksManager.deleteTrack(trackId)
  }

  func moveBookmark(_ bookmarkId: MWMMarkID, toGroupId groupId: MWMMarkGroupID) {
    bookmarksManager.moveBookmark(bookmarkId, toGroupId: groupId)
  }
  
  func moveTrack(_ trackId: MWMTrackID, toGroupId groupId: MWMMarkGroupID) {
    bookmarksManager.moveTrack(trackId, toGroupId: groupId)
  }

  func updateBookmark(_ bookmarkId: MWMMarkID, setGroupId groupId: MWMMarkGroupID, title: String, color: BookmarkColor, description: String) {
    bookmarksManager.updateBookmark(bookmarkId, setGroupId: groupId, title: title, color: color, description: description)
  }

  func updateTrack(_ trackId: MWMTrackID, setGroupId groupId: MWMMarkGroupID) {
    bookmarksManager.moveTrack(trackId, toGroupId: groupId)
  }

  func deleteBookmarksGroup() {
    bookmarksManager.deleteCategory(markGroupId)
  }

  func canDeleteGroup() -> Bool {
    bookmarksManager.userCategoriesCount() > 1
  }

  func exportFile(_ completion: @escaping SharingResultCompletionHandler) {
    bookmarksManager.shareCategory(markGroupId, completion: completion)
  }

  func finishExportFile() {
    bookmarksManager.finishShareCategory()
  }
}
