abstract class BaseRepository<T> {
  Future<T> fetchFromRemote();
  Future<T?> fetchFromCache();
  Future<void> saveToCache(T data);

  Future<T> getData() async {
    final cached = await fetchFromCache();
    if (cached != null) return cached;
    final remote = await fetchFromRemote();
    await saveToCache(remote);
    return remote;
  }

  Future<void> refresh() async {
    final remote = await fetchFromRemote();
    await saveToCache(remote);
  }
}
