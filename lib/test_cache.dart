import '../services/project_info_cache_service.dart';

/// Testing script for ProjectInfoCacheService functionality
/// Run this to verify cache system is working correctly
class TestProjectInfoCache {
  static Future<void> runCacheTest() async {
    

    // Clear any existing cache
    await ProjectInfoCacheService.clearCache();
    

    // Test 1: Save data to cache
    
    final saveResult = await ProjectInfoCacheService.saveProjectInfoData(
      numberOfModules: 5,
      numberOfZones: 25,
    );
    

    // Test 2: Retrieve data from cache
    
    final cachedModules = await ProjectInfoCacheService.getCachedNumberOfModules();
    final cachedZones = await ProjectInfoCacheService.getCachedNumberOfZones();
    

    // Test 3: Verify data integrity
    
    final modulesMatch = cachedModules == 5;
    final zonesMatch = cachedZones == 25;
    

    // Test 4: Get cache info
    
    final cacheInfo = await ProjectInfoCacheService.getCacheInfo();
    

    // Final result
    final allTestsPassed = saveResult && modulesMatch && zonesMatch;
    
    
  }
}