local common = import 'common.libsonnet';

// DO NOT USE the hardlinking configuration below unless really needed.
// This example only exists for reference in situations
// where the more efficient FUSE worker is not supported.
{
  blobstore: common.blobstore,
  browserUrl: common.browserUrl,
  maximumMessageSizeBytes: common.maximumMessageSizeBytes,
  scheduler: { address: 'scheduler:8983' },
  global: common.global,
  buildDirectories: [{
    native: {
      buildDirectoryPath: '/worker/build',
      cacheDirectoryPath: '/worker/cache',
      maximumCacheFileCount: 10000,
      maximumCacheSizeBytes: 1024 * 1024 * 1024,
      cacheReplacementPolicy: 'LEAST_RECENTLY_USED',
    },
    runners: [{
      endpoint: { address: 'unix:///worker/runner' },
      concurrency: 8,
      instanceNamePrefix: 'hardlinking',
      platform: {
        properties: [
          { name: 'OSFamily', value: 'linux' },
	   { name: 'container-image', value: 'docker://gcr.io/chops-public-images-prod/rbe/siso-chromium/linux@sha256:26de99218a1a8b527d4840490bcbf1690ee0b55c84316300b60776e6b3a03fe1' },
        ],
      },
      workerId: {
        datacenter: 'local',
        rack: '1',
        slot: '1',
        hostname: 'worker-hardlinking',
      },
    }],
  }],
  inputDownloadConcurrency: 10,
  outputUploadConcurrency: 11,
  directoryCache: {
    maximumCount: 1000,
    maximumSizeBytes: 1000 * 1024,
    cacheReplacementPolicy: 'LEAST_RECENTLY_USED',
  },
}
