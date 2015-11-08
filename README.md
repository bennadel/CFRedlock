
# CFRedlock For ColdFusion

by [Ben Nadel][bennadel] (on [Google+][googleplus])

[Redlock][redlock] is a distributed locking algorithm, proposed by the Redis team. Unlike
other "vanilla" distributed locking algorithms, however, Redlock is intended to provide 
stronger guarantees around safety and liveness:

* Safety property: Mutual exclusion. At any given moment, only one client can hold a 
  lock.
* Liveness property A: Deadlock free. Eventually it is always possible to acquire a lock,
  even if the client that locked a resource crashed or gets partitioned.
* Liveness property B: Fault tolerance. As long as the majority of Redis nodes are up, 
  clients are able to acquire and release locks.

CFRedlock is my ColdFusion implementation of the Redlock distributed locking algorithm. 
And, while it is designed to use Redis as the shared source of truth for locks, the 
concept of a "key server" is abstracted and can use anything, including a single, 
isolated instance of ColdFusion (which uses CFLock internally for synchronization).

For CFRedlock, the Redis client is powered by Jedis and depends on the Jedis JAR file 
(and its dependency on the Apache commons Pool2 library). However, you can write your
own KeyServer implementation that uses any driver that you want.

## Creating The Distributed Locking Client

To start using CFRedlock, you need to create the distributed locking client. You can 
instantiated the DistributedLockClient.cfc yourself:

```cfc
var locking = new lib.client.DistributedLockClient( 
	keyServers,
	retryDelayInMilliseconds,
	maxRetryCount 
);
```

... or, you can use the client factory to produce the various types of clients:

```cfc
// Create a Jedis-powered client - requires an array of JedisPool instances.
var locking = new lib.CFRedlock().createJedisClient( 
	jedisPools,
	retryDelayInMilliseconds,
	maxRetryCount
);

// Create an ISOLATED ColdFusion client (uses CFLock internally).
var locking = new lib.CFRedlock().createIsolatedClient( 
	retryDelayInMilliseconds,
	maxRetryCount
);

// Create a test client with static GET / DELETE behavior.
var locking = new lib.CFRedlock().createTestClient(
	[
		[ true, true ],
		[ false, false ],
		[ true, true ]
	],
	retryDelayInMilliseconds,
	maxRetryCount
);
```

### Why An Isolated ColdFusion Instance?

It may seem odd to provide an isolated, single-ColdFusion instance version of Redlock.
However, this can help with migrations. Let's say that you want to start implementing
distributed locking, but you don't have infrastructure in place. You can switch from 
your native CFLock usage over to the Isolated version of Redlock. This way, you put in
the ground-work for the distributed locking workflow. Then, when you have a set of Redis
servers ready to rock, switching from the Isolated version to the fully distributed, 
Redis-powered version should be a drop-in replacement.

## The Distributed Locking Workflow

Using a service is a little bit more involved than using the native ColdFusion CFLock 
tag. But, not by all that much. More than anything, you just have to be careful to always
release the lock when you are done with it.

NOTE: If you forget to release a lock, the key will expire eventually - this part of the
"Liveness" property guarantee of Redlock.

```cfc
var myLock = lockingClient.getLock( "my-lock-name", expirationInMilliseconds );

try {
	
	someSynchronizedAction();

// No matter what, release the lock when you are done with it.
} finally {
	
	myLock.releaseLock();

}
```

Unlike the native CFLock mechanism, there is no "timeout" for how long the calling 
context will wait to acquire a lock. However, the locking client has a setting for the
number of times that it will try (and retry) to obtain the lock. Personally, this feels
like an easy mental model.

**CAUTION**: If the lock cannot be obtained, an error will be thrown.

If you wanted to abstract some of this workflow, you could probably write a ColdFusion
custom tag and then [use it in your CFScript / CFComponent context in ColdFusion 11](http://www.bennadel.com/blog/2587-robust-cfscript-suport-for-tags-in-coldfusion-11-beta.htm).


[bennadel]: http://www.bennadel.com
[googleplus]: https://plus.google.com/108976367067760160494?rel=author
[redlock]: http://redis.io/topics/distlock