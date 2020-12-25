package com.netbric.s5.conductor;
/**
 * a replica id is composed as:
 * bit[63..24]  volume index, generated by conductor
 * bit[23..4] shard index
 * bit[3..0] replica index
 * while the volume id is: <volume_index> << 24
 */
public class VolumeIdUtils {
	static public long replicaToVolumeId(long repId) {
		return repId & 0xffffffffff000000L;
	}
	static public long replicaToShardId(long repId) {
		return repId & 0xffffffffffffff00L;
	}
}
